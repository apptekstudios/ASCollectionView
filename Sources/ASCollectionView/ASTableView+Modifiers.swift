// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: PUBLIC Modifier: OnScroll / OnReachedBottom

@available(iOS 13.0, *)
public extension ASTableView
{
	/// Set a closure that is called whenever the tableView is scrolled
	func onScroll(_ onScroll: @escaping OnScrollCallback) -> Self
	{
		var this = self
		this.onScrollCallback = onScroll
		return this
	}

	/// Set a closure that is called whenever the tableView is scrolled to the bottom.
	/// This is useful to enable loading more data when scrolling to bottom
	func onReachedBottom(_ onReachedBottom: @escaping OnReachedBottomCallback) -> Self
	{
		var this = self
		this.onReachedBottomCallback = onReachedBottom
		return this
	}

	/// Set whether to show separators between cells
	func separatorsEnabled(_ isEnabled: Bool = true) -> Self
	{
		var this = self
		this.separatorsEnabled = isEnabled
		return this
	}

	/// Set whether to show scroll indicator
	func scrollIndicatorEnabled(_ isEnabled: Bool = true) -> Self
	{
		var this = self
		this.scrollIndicatorEnabled = isEnabled
		return this
	}

	/// Set the content insets
	func contentInsets(_ insets: UIEdgeInsets) -> Self
	{
		var this = self
		this.contentInsets = insets
		return this
	}

	/// Set a closure that is called when the tableView is pulled to refresh
	func onPullToRefresh(_ callback: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?) -> Self
	{
		var this = self
		this.onPullToRefresh = callback
		return this
	}

	/// Set whether the TableView should always allow bounce vertically
	func alwaysBounce(_ alwaysBounce: Bool = true) -> Self
	{
		var this = self
		this.alwaysBounce = alwaysBounce
		return this
	}

	/// Set whether the TableView should animate on data refresh
	func animateOnDataRefresh(_ animate: Bool = true) -> Self
	{
		var this = self
		this.animateOnDataRefresh = animate
		return this
	}
}

// MARK: ASTableView specific header modifiers

@available(iOS 13.0, *)
public extension ASTableViewSection
{
	func sectionHeaderInsetGrouped<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		let insetGroupedContent =
			content()
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 12, leading: 0, bottom: 6, trailing: 0))

		section.setHeaderView(insetGroupedContent)
		return section
	}
}

@available(iOS 13.0, *)
public extension ASTableView
{
	func shrinkToContentSize(isEnabled: Bool = true) -> some View
	{
		SelfSizingWrapper(content: self, shrinkDirection: .vertical, isEnabled: isEnabled)
	}

	func fitContentSize(isEnabled: Bool = true) -> some View
	{
		SelfSizingWrapper(content: self, shrinkDirection: .vertical, isEnabled: isEnabled, expandToFitMode: true)
	}
}
