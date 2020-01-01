// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

struct EnvironmentKeyInvalidateCellLayout: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

struct EnvironmentKeyASScrollIndicatorsEnabled: EnvironmentKey
{
	static let defaultValue: Bool = true
}

struct EnvironmentKeyASContentInsets: EnvironmentKey
{
	static let defaultValue: UIEdgeInsets = .zero
}

struct EnvironmentKeyASTableViewSeparatorsEnabled: EnvironmentKey
{
	static let defaultValue: Bool = true
}

struct EnvironmentKeyASTableViewOnReachedBottom: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

struct EnvironmentKeyASCollectionViewOnReachedBoundary: EnvironmentKey
{
	static let defaultValue: ((Boundary) -> Void) = { _ in }
}

struct EnvironmentKeyASAlwaysBounceVertical: EnvironmentKey
{
	static let defaultValue: Bool = false
}

struct EnvironmentKeyASAlwaysBounceHorizontal: EnvironmentKey
{
	static let defaultValue: Bool = false
}

struct EnvironmentKeyASInitialScrollPosition: EnvironmentKey
{
	static let defaultValue: ASCollectionViewScrollPosition? = nil
}

public extension EnvironmentValues
{
	var invalidateCellLayout: () -> Void
	{
		get { return self[EnvironmentKeyInvalidateCellLayout.self] }
		set { self[EnvironmentKeyInvalidateCellLayout.self] = newValue }
	}

	var scrollIndicatorsEnabled: Bool
	{
		get { return self[EnvironmentKeyASScrollIndicatorsEnabled.self] }
		set { self[EnvironmentKeyASScrollIndicatorsEnabled.self] = newValue }
	}

	var contentInsets: UIEdgeInsets
	{
		get { return self[EnvironmentKeyASContentInsets.self] }
		set { self[EnvironmentKeyASContentInsets.self] = newValue }
	}

	var tableViewSeparatorsEnabled: Bool
	{
		get { return self[EnvironmentKeyASTableViewSeparatorsEnabled.self] }
		set { self[EnvironmentKeyASTableViewSeparatorsEnabled.self] = newValue }
	}

	var tableViewOnReachedBottom: () -> Void
	{
		get { return self[EnvironmentKeyASTableViewOnReachedBottom.self] }
		set { self[EnvironmentKeyASTableViewOnReachedBottom.self] = newValue }
	}

	var collectionViewOnReachedBoundary: (Boundary) -> Void
	{
		get { self[EnvironmentKeyASCollectionViewOnReachedBoundary.self] }
		set { self[EnvironmentKeyASCollectionViewOnReachedBoundary.self] = newValue }
	}

	var alwaysBounceVertical: Bool
	{
		get { return self[EnvironmentKeyASAlwaysBounceVertical.self] }
		set { self[EnvironmentKeyASAlwaysBounceVertical.self] = newValue }
	}

	var alwaysBounceHorizontal: Bool
	{
		get { return self[EnvironmentKeyASAlwaysBounceHorizontal.self] }
		set { self[EnvironmentKeyASAlwaysBounceHorizontal.self] = newValue }
	}

	var initialScrollPosition: ASCollectionViewScrollPosition?
	{
		get { return self[EnvironmentKeyASInitialScrollPosition.self] }
		set { self[EnvironmentKeyASInitialScrollPosition.self] = newValue }
	}
}

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
