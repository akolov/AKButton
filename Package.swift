// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AKButton",
  platforms: [
    .iOS(.v12), .tvOS(.v12)
  ],
  products: [
    .library(name: "AKButton", targets: ["AKButton"]),
    .library(name: "AKRxButton", targets: ["AKRxButton"])
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1")
  ],
  targets: [
    .target(name: "AKButton", dependencies: []),
    .target(name: "AKRxButton", dependencies: ["AKButton", "RxCocoa", "RxSwift"])
  ]
)
