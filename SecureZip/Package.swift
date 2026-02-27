// swift-tools-version: 5.9
// ============================================================
// Package.swift - SPM 依存関係定義
//
// このファイルは外部ライブラリのバージョン管理のために使用します。
// Xcode プロジェクトでは、Xcode の「Add Package Dependency」から
// 以下のパッケージを追加してください。
// ============================================================

import PackageDescription

let package = Package(
    name: "SecureZip",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "SecureZip", targets: ["SecureZip"])
    ],
    dependencies: [
        // Google Sign-In SDK for macOS（OAuth 2.0 認証）
        // https://github.com/google/GoogleSignIn-iOS
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS.git",
            from: "7.0.0"
        ),
        // GTMAppAuth - OAuth トークン管理・自動リフレッシュ
        // https://github.com/google/GTMAppAuth
        .package(
            url: "https://github.com/google/GTMAppAuth.git",
            from: "4.0.0"
        ),
    ],
    targets: [
        .target(
            name: "SecureZip",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GTMAppAuth", package: "GTMAppAuth"),
            ],
            path: "SecureZip",
            linkerSettings: [
                // libarchive はmacOS標準搭載なので追加バンドル不要
                .linkedLibrary("archive")
            ]
        ),
        .testTarget(
            name: "SecureZipTests",
            dependencies: ["SecureZip"],
            path: "SecureZipTests"
        ),
    ]
)
