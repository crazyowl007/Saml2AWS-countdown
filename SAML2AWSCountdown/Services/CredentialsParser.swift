import Foundation

struct CredentialsParser {
    static let defaultPath = (NSHomeDirectory() as NSString).appendingPathComponent(".aws/credentials")

    static func parse(filePath: String = defaultPath) -> SAMLCredentials? {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return nil
        }
        return parse(content: content)
    }

    static func parse(content: String) -> SAMLCredentials? {
        var inSamlSection = false
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let section = trimmed.dropFirst().dropLast()
                inSamlSection = (section == "saml")
                continue
            }

            if inSamlSection && trimmed.hasPrefix("x_security_token_expires") {
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                if let date = parseISO8601(value) {
                    return SAMLCredentials(expiresAt: date)
                }
            }
        }
        return nil
    }

    private static func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
