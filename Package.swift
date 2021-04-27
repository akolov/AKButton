// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "AKButton",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(name: "AKButton", targets: ["AKButton"]),
    .library(name: "AKRxButton", targets: ["AKRxButton"])
  ],
  dependencies: [
    .package(name: "RxSwift", url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.1.0"))
  ],
  targets: [
    .target(name: "AKButton", dependencies: []),
    .target(
      name: "AKRxButton",
      dependencies: [
        "AKButton",
        .product(name: "RxCocoa", package: "RxSwift"),
        .product(name: "RxSwift", package: "RxSwift")
      ]
    )
  ]
)
