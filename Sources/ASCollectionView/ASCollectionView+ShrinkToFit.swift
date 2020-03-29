// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

@available(iOS 13.0, *)
protocol ContentSize
{
	var contentSizeTracker: ContentSizeTracker? { get set }
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
	@State var contentSizeTracker = ContentSizeTracker()

	var content: Content
	var shrinkDirection: ShrinkDimension
	var isEnabled: Bool = true

	var modifiedContent: Content
	{
		var content = self.content
		content.contentSizeTracker = contentSizeTracker
		return content
	}

	var body: some View
	{
		SubWrapper(contentSizeTracker: contentSizeTracker, content: modifiedContent, shrinkDirection: shrinkDirection, isEnabled: isEnabled)
	}
}

@available(iOS 13.0, *)
struct SubWrapper<Content: View & ContentSize>: View
{
	@ObservedObject
	var contentSizeTracker: ContentSizeTracker

	var content: Content
	var shrinkDirection: ShrinkDimension
	var isEnabled: Bool

	var body: some View
	{
		content
			.frame(
				idealWidth: isEnabled && shrinkDirection.shrinkHorizontal ? contentSizeTracker.contentSize?.width : nil,
				maxWidth: isEnabled && shrinkDirection.shrinkHorizontal ? contentSizeTracker.contentSize?.width : nil,
				idealHeight: isEnabled && shrinkDirection.shrinkVertical ? contentSizeTracker.contentSize?.height : nil,
				maxHeight: isEnabled && shrinkDirection.shrinkVertical ? contentSizeTracker.contentSize?.height : nil,
				alignment: .topLeading)
	}
}

@available(iOS 13.0, *)
class ContentSizeTracker: ObservableObject
{
	@Published
	var contentSize: CGSize?
}

@available(iOS 13.0, *)
public extension ASCollectionView
{
	func shrinkToContentSize(isEnabled: Bool = true, dimension: ShrinkDimension) -> some View
	{
		SelfSizingWrapper(content: self, shrinkDirection: dimension, isEnabled: isEnabled)
	}
}

@available(iOS 13.0, *)
public extension ASTableView
{
	func shrinkToContentSize(isEnabled: Bool = true) -> some View
	{
		SelfSizingWrapper(content: self, shrinkDirection: .vertical, isEnabled: isEnabled)
	}
}
