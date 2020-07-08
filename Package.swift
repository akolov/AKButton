// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AKButton",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "AKButton",
      targets: ["AKButton"]
    ),
  ],
  targets: [
    .target(
      name: "AKButton",
      dependencies: []
    )
  ]
)
