// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SAML2AWSCountdown",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SAML2AWSCountdown",
            path: "SAML2AWSCountdown",
            exclude: ["Info.plist", "SAML2AWSCountdown.entitlements"]
        )
    ]
)
