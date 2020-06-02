// ASCollectionView. Created by Apptek Studios 2019

import CoreGraphics

struct ASOptionalSize
{
	let width: CGFloat?
	let height: CGFloat?

	init(width: CGFloat? = nil, height: CGFloat? = nil)
	{
		self.width = width
		self.height = height
	}

	init(_ size: CGSize)
	{
		width = size.width
		height = size.height
	}

	static let none = ASOptionalSize()
}

extension CGFloat
{
	func applyOptionalMinBound(_ optionalMinBound: CGFloat?) -> CGFloat
	{
		optionalMinBound.map { Swift.max($0, self) } ?? self
	}

	func applyOptionalMaxBound(_ optionalMaxBound: CGFloat?) -> CGFloat
	{
		optionalMaxBound.map { Swift.min($0, self) } ?? self
	}
}

extension CGSize
{
	func applyMinSize(_ minSize: ASOptionalSize) -> CGSize
	{
		CGSize(
			width: width.applyOptionalMinBound(minSize.width),
			height: height.applyOptionalMinBound(minSize.height))
	}

	func applyMaxSize(_ maxSize: ASOptionalSize) -> CGSize
	{
		CGSize(
			width: width.applyOptionalMaxBound(maxSize.width),
			height: height.applyOptionalMaxBound(maxSize.height))
	}
}
