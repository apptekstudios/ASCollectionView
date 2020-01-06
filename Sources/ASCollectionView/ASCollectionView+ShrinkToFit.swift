// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

@available(iOS 13.0, *)
protocol ContentSize
{
	var contentSize: Binding<CGSize?>? { get set }
}

@available(iOS 13.0, *)
public enum ShrinkDimension
{
	case horizontal
	case vertical

	var shrinkVertical: Bool
	{
		self == .vertical
	}

	var shrinkHorizontal: Bool
	{
		self == .horizontal
	}
}

@available(iOS 13.0, *)
struct SelfSizingWrapper<Content: View & ContentSize>: View
{
	var contentSize: Binding<CGSize?>
	var content: Content
	var shrinkDirection: ShrinkDimension
	var isEnabled: Bool

	init(_ content: Content, isEnabled: Bool, contentSize: Binding<CGSize?>, shrinkDirection: ShrinkDimension)
	{
		self.content = content
		self.contentSize = contentSize
		self.shrinkDirection = shrinkDirection
		self.isEnabled = isEnabled

		self.content.contentSize = contentSize
	}

	var body: some View
	{
		content
			.frame(
				idealWidth: isEnabled && shrinkDirection.shrinkHorizontal ? contentSize.wrappedValue?.width : nil,
				maxWidth: isEnabled && shrinkDirection.shrinkHorizontal ? contentSize.wrappedValue?.width : nil,
				idealHeight: isEnabled && shrinkDirection.shrinkVertical ? contentSize.wrappedValue?.height : nil,
				maxHeight: isEnabled && shrinkDirection.shrinkVertical ? contentSize.wrappedValue?.height : nil,
				alignment: .topLeading)
	}
}

@available(iOS 13.0, *)
public extension ASCollectionView
{
	func shrinkToContentSize(isEnabled: Bool, _ contentSize: Binding<CGSize?>, dimensionToShrink: ShrinkDimension) -> some View
	{
		SelfSizingWrapper(self, isEnabled: isEnabled, contentSize: contentSize, shrinkDirection: dimensionToShrink)
	}
}
