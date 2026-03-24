import Foundation

enum RefreshState: Equatable {
    case idle
    case refreshing(String)
    case success
    case failed(String)
}

final class SAML2AWSLoginService {
    private let saml2awsPath = "/opt/homebrew/bin/saml2aws"

    private var childPid: pid_t = 0
    private var masterFd: Int32 = -1
    private var timeoutWorkItem: DispatchWorkItem?
    private var mfaAlreadySent = false
    private var isRunning = false

    func login(
        onStateChange: @escaping (RefreshState) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        mfaAlreadySent = false
        isRunning = true

        DispatchQueue.main.async {
            onStateChange(.refreshing("Starting login..."))
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runWithPTY(onStateChange: onStateChange, completion: completion)
        }
    }

    func cancel() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        isRunning = false
        if childPid > 0 {
            kill(childPid, SIGTERM)
            childPid = 0
        }
        if masterFd >= 0 {
            close(masterFd)
            masterFd = -1
        }
    }

    private func runWithPTY(
        onStateChange: @escaping (RefreshState) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        var master: Int32 = 0
        var pid: pid_t = 0

        // forkpty creates a pseudo-terminal and forks
        pid = forkpty(&master, nil, nil, nil)

        if pid < 0 {
            // fork failed
            DispatchQueue.main.async {
                onStateChange(.failed("Failed to create pseudo-terminal"))
                completion(false)
            }
            return
        }

        if pid == 0 {
            // Child process: exec saml2aws
            let args = [saml2awsPath, "login", "--skip-prompt", "--force"]
            let cArgs = args.map { strdup($0) } + [nil]
            execv(saml2awsPath, cArgs)
            // If execv returns, it failed
            _exit(1)
        }

        // Parent process
        self.masterFd = master
        self.childPid = pid

        // Set up timeout (120 seconds)
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.cancel()
            DispatchQueue.main.async {
                onStateChange(.failed("Timeout waiting for MFA approval"))
                completion(false)
            }
        }
        self.timeoutWorkItem = timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 120, execute: timeout)

        // Read output from PTY in a loop
        var outputBuffer = ""
        let bufSize = 4096
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
        defer { buf.deallocate() }

        while isRunning {
            let bytesRead = read(master, buf, bufSize)
            if bytesRead <= 0 { break }

            if let str = String(bytes: UnsafeBufferPointer(start: buf, count: bytesRead), encoding: .utf8) {
                outputBuffer += str

                // saml2aws uses an arrow-key interactive selector (Go survey lib).
                // The default selection is the first option (PUSH MFA).
                // When we see the MFA prompt, just send Enter to confirm default.
                if !mfaAlreadySent && outputBuffer.contains("Select which MFA option") {
                    mfaAlreadySent = true
                    // Send Enter to confirm the default (first) MFA option
                    var enter: [UInt8] = [0x0d] // CR = Enter
                    _ = Darwin.write(master, &enter, 1)
                    DispatchQueue.main.async {
                        onStateChange(.refreshing("MFA selected, waiting for push..."))
                    }
                }

                if outputBuffer.contains("Waiting for approval") {
                    DispatchQueue.main.async {
                        onStateChange(.refreshing("Waiting for Okta push approval..."))
                    }
                }
            }
        }

        // Wait for child process to finish
        var status: Int32 = 0
        waitpid(pid, &status, 0)

        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        isRunning = false

        if masterFd >= 0 {
            close(masterFd)
            masterFd = -1
        }
        childPid = 0

        // WIFEXITED/WEXITSTATUS are C macros unavailable in Swift
        let exitCode = (status & 0x7f) == 0 ? Int32((status >> 8) & 0xff) : Int32(-1)

        DispatchQueue.main.async {
            if exitCode == 0 {
                onStateChange(.success)
                completion(true)
            } else {
                let lastLines = outputBuffer.components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    .suffix(3)
                    .joined(separator: "\n")
                let msg = lastLines.isEmpty ? "Login failed (exit code \(exitCode))" : String(lastLines.suffix(200))
                onStateChange(.failed(msg))
                completion(false)
            }
        }
    }

}
