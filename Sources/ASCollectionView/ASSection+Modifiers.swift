// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: SUPPLEMENTARY VIEWS - PUBLIC MODIFIERS

@available(iOS 13.0, *)
public extension ASCollectionViewSection
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
		section.dataSource.setSelfSizingConfig(config: config)
		return section
	}
}
