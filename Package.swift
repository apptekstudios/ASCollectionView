// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "ASCollectionView",
                      platforms: [.iOS(.v11)],
                      products: [// Products define the executables and libraries produced by a package, and make them visible to other packages.
                      	.library(name: "ASCollectionView",
                      	         targets: ["ASCollectionView"]),
                        .library(name: "ASCollectionViewDynamic", type: .dynamic, targets: ["ASCollectionView"]),
					  ],
                      dependencies: [
						.package(url: "https://github.com/ra1028/DifferenceKit", .upToNextMajor(from: Version(1, 1, 5)))
                      ],
                      targets: [
                      	.target(name: "ASCollectionView",
                      	        dependencies: ["DifferenceKit"]),
					  ]
)
