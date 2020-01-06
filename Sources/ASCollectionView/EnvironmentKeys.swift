// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct EnvironmentKeyInvalidateCellLayout: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

@available(iOS 13.0, *)
struct EnvironmentKeyASScrollIndicatorsEnabled: EnvironmentKey
{
	static let defaultValue: Bool = true
}

@available(iOS 13.0, *)
struct EnvironmentKeyASContentInsets: EnvironmentKey
{
	static let defaultValue: UIEdgeInsets = .zero
}

@available(iOS 13.0, *)
struct EnvironmentKeyASTableViewSeparatorsEnabled: EnvironmentKey
{
	static let defaultValue: Bool = true
}

@available(iOS 13.0, *)
struct EnvironmentKeyASTableViewOnPullToRefresh: EnvironmentKey
{
	static let defaultValue: (((_ endRefreshing: @escaping (() -> Void)) -> Void)?) = nil
}

@available(iOS 13.0, *)
struct EnvironmentKeyASTableViewOnReachedBottom: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

@available(iOS 13.0, *)
struct EnvironmentKeyASCollectionViewOnReachedBoundary: EnvironmentKey
{
	static let defaultValue: ((Boundary) -> Void) = { _ in }
}

@available(iOS 13.0, *)
struct EnvironmentKeyASAlwaysBounceVertical: EnvironmentKey
{
	static let defaultValue: Bool = false
}

@available(iOS 13.0, *)
struct EnvironmentKeyASAlwaysBounceHorizontal: EnvironmentKey
{
	static let defaultValue: Bool = false
}

@available(iOS 13.0, *)
struct EnvironmentKeyASInitialScrollPosition: EnvironmentKey
{
	static let defaultValue: ASCollectionViewScrollPosition? = nil
}

@available(iOS 13.0, *)
public extension EnvironmentValues
{
	var invalidateCellLayout: () -> Void
	{
		get { self[EnvironmentKeyInvalidateCellLayout.self] }
		set { self[EnvironmentKeyInvalidateCellLayout.self] = newValue }
	}

	var scrollIndicatorsEnabled: Bool
	{
		get { self[EnvironmentKeyASScrollIndicatorsEnabled.self] }
		set { self[EnvironmentKeyASScrollIndicatorsEnabled.self] = newValue }
	}

	var contentInsets: UIEdgeInsets
	{
		get { self[EnvironmentKeyASContentInsets.self] }
		set { self[EnvironmentKeyASContentInsets.self] = newValue }
	}

	var tableViewSeparatorsEnabled: Bool
	{
		get { self[EnvironmentKeyASTableViewSeparatorsEnabled.self] }
		set { self[EnvironmentKeyASTableViewSeparatorsEnabled.self] = newValue }
	}

	var tableViewOnPullToRefresh: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?
	{
		get { self[EnvironmentKeyASTableViewOnPullToRefresh.self] }
		set { self[EnvironmentKeyASTableViewOnPullToRefresh.self] = newValue }
	}

	var tableViewOnReachedBottom: () -> Void
	{
		get { self[EnvironmentKeyASTableViewOnReachedBottom.self] }
		set { self[EnvironmentKeyASTableViewOnReachedBottom.self] = newValue }
	}

	var collectionViewOnReachedBoundary: (Boundary) -> Void
	{
		get { self[EnvironmentKeyASCollectionViewOnReachedBoundary.self] }
		set { self[EnvironmentKeyASCollectionViewOnReachedBoundary.self] = newValue }
	}

	var alwaysBounceVertical: Bool
	{
		get { self[EnvironmentKeyASAlwaysBounceVertical.self] }
		set { self[EnvironmentKeyASAlwaysBounceVertical.self] = newValue }
	}

	var alwaysBounceHorizontal: Bool
	{
		get { self[EnvironmentKeyASAlwaysBounceHorizontal.self] }
		set { self[EnvironmentKeyASAlwaysBounceHorizontal.self] = newValue }
	}

	var initialScrollPosition: ASCollectionViewScrollPosition?
	{
		get { self[EnvironmentKeyASInitialScrollPosition.self] }
		set { self[EnvironmentKeyASInitialScrollPosition.self] = newValue }
	}
}

@available(iOS 13.0, *)
public extension View
{
	/// Set whether to show scroll indicators for the ASCollectionView/ASTableView
	func scrollIndicatorsEnabled(_ enabled: Bool) -> some View
	{
		environment(\.scrollIndicatorsEnabled, enabled)
	}

	/// Set insets for the ASCollectionView/ASTableView
	func contentInsets(_ insets: UIEdgeInsets) -> some View
	{
		environment(\.contentInsets, insets)
	}

	/// Set whether the ASTableView should show separators
	func tableViewSeparatorsEnabled(_ enabled: Bool) -> some View
	{
		environment(\.tableViewSeparatorsEnabled, enabled)
	}

	/// Set a closure that is called when the tableView is pulled to refresh
	func onTableViewPullToRefresh(_ onPullToRefresh: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?) -> some View
	{
		environment(\.tableViewOnPullToRefresh, onPullToRefresh)
	}

	/// Set a closure that is called whenever the tableView is scrolled to the bottom.
	/// This is useful to enable loading more data when scrolling to bottom
	func onTableViewReachedBottom(_ onReachedBottom: @escaping (() -> Void)) -> some View
	{
		environment(\.tableViewOnReachedBottom, onReachedBottom)
	}

	/// Set a closure that is called whenever the collectionView is scrolled to a boundary. eg. the bottom.
	/// This is useful to enable loading more data when scrolling to bottom
	func onCollectionViewReachedBoundary(_ onReachedBoundary: @escaping ((Boundary) -> Void)) -> some View
	{
		environment(\.collectionViewOnReachedBoundary, onReachedBoundary)
	}

	/// Set whether the ASCollectionView should always allow horizontal bounce
	func alwaysBounceHorizontal(_ alwaysBounce: Bool = true) -> some View
	{
		environment(\.alwaysBounceHorizontal, alwaysBounce)
	}

	/// Set whether the ASCollectionView/ASTableView should always allow horizontal bounce
	func alwaysBounceVertical(_ alwaysBounce: Bool = true) -> some View
	{
		environment(\.alwaysBounceVertical, alwaysBounce)
	}

	/// Set an initial scroll position for the ASCollectionView
	func initialScrollPosition(_ scrollPosition: ASCollectionViewScrollPosition?) -> some View
	{
		environment(\.initialScrollPosition, scrollPosition)
	}
}
