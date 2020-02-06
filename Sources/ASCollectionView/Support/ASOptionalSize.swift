//
//  File.swift
//  
//
//  Created by Toby Brennan on 6/2/20.
//

import CoreGraphics

struct ASOptionalSize {
	let width: CGFloat?
	let height: CGFloat?

	init(width: CGFloat? = nil, height: CGFloat? = nil) {
		self.width = width
		self.height = height
	}
	
	init(_ size: CGSize) {
		self.width = size.width
		self.height = size.height
	}
	
	static let none = ASOptionalSize()
}

extension CGSize {
	func applyMinSize(_ minSize: ASOptionalSize) -> CGSize {
		CGSize(width: minSize.width.map { max($0, width) } ?? width,
			   height: minSize.height.map { max($0, height) } ?? height)
	}
	func applyMaxSize(_ maxSize: ASOptionalSize) -> CGSize {
		CGSize(width: maxSize.width.map { min($0, width) } ?? width,
			   height: maxSize.height.map { min($0, height) } ?? height)
	}
}
