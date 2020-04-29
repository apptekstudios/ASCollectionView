// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: SUPPLEMENTARY VIEWS - PUBLIC MODIFIERS

@available(iOS 13.0, *)
public extension ASSection
{
	func sectionHeader<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		section.setHeaderView(content())
		return section
	}

	func sectionFooter<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		section.setFooterView(content())
		return section
	}

	func sectionSupplementary<Content: View>(ofKind kind: String, content: () -> Content?) -> Self
	{
		var section = self
		section.setSupplementaryView(content(), ofKind: kind)
		return section
	}

	func tableViewSetEstimatedSizes(headerHeight: CGFloat? = nil, footerHeight: CGFloat? = nil) -> Self
	{
		var section = self
		section.estimatedHeaderHeight = headerHeight
		section.estimatedFooterHeight = footerHeight
		return section
	}

	func tableViewDisableDefaultTheming() -> Self
	{
		var section = self
		section.disableDefaultTheming = true
		return section
	}

	func tableViewSeparatorInsets(leading: CGFloat = 0, trailing: CGFloat = 0) -> Self
	{
		var section = self
		section.tableViewSeparatorInsets = UIEdgeInsets(top: 0, left: leading, bottom: 0, right: trailing)
		return section
	}

	// Use this modifier to make a section's cells be cached even when off-screen. This is useful for cells containing nested collection views
	func cacheCells() -> Self
	{
		var section = self
		section.shouldCacheCells = true
		return section
	}

	// MARK: Self-sizing config

	func selfSizingConfig(_ config: @escaping SelfSizingConfig) -> Self
	{
		var section = self
		section.setSelfSizingConfig(config: config)
		return section
	}

	func selectedItems(_ selectedItemsBinding: Binding<Set<Int>>? = nil) -> Self
	{
		var section = self
		section.selectedItems = selectedItemsBinding
		return section
	}

	func shouldAllowSelection(_ shouldAllow: ((_ index: Int) -> Bool)? = nil) -> Self
	{
		var section = self
		section.shouldAllowSelection = shouldAllow
		return section
	}

	func shouldAllowDeselection(_ shouldAllow: ((_ index: Int) -> Bool)? = nil) -> Self
	{
		var section = self
		section.shouldAllowDeselection = shouldAllow
		return section
	}

	func onCellEvent(_ onCellEvent: OnCellEvent<DataCollection.Element>? = nil) -> Self
	{
		var section = self
		section.onCellEvent = onCellEvent
		return section
	}

	func dragDropConfig(_ config: ASDragDropConfig<DataCollection.Element>) -> Self
	{
		var section = self
		section.dragDropConfig = config
		return section
	}

	func shouldAllowSwipeToDelete(_ shouldAllow: ShouldAllowSwipeToDelete? = nil) -> Self
	{
		var section = self
		section.shouldAllowSwipeToDelete = shouldAllow
		return section
	}

	func onSwipeToDelete(_ onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>? = nil) -> Self
	{
		var section = self
		section.onSwipeToDelete = onSwipeToDelete
		return section
	}

	func contextMenuProvider(_ provider: ContextMenuProvider<DataCollection.Element>? = nil) -> Self
	{
		var section = self
		section.contextMenuProvider = provider
		return section
	}
}
