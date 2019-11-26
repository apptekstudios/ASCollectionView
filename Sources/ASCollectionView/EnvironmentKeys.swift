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
	func scrollIndicatorsEnabled(_ enabled: Bool) -> some View
	{
		environment(\.scrollIndicatorsEnabled, enabled)
	}

	func contentInsets(_ insets: UIEdgeInsets) -> some View
	{
		environment(\.contentInsets, insets)
	}

	func tableViewSeparatorsEnabled(_ enabled: Bool) -> some View
	{
		environment(\.tableViewSeparatorsEnabled, enabled)
	}

	func onTableViewReachedBottom(_ onReachedBottom: @escaping (() -> Void)) -> some View
	{
		environment(\.tableViewOnReachedBottom, onReachedBottom)
	}

	func alwaysBounceHorizontal(_ alwaysBounce: Bool = true) -> some View
	{
		environment(\.alwaysBounceHorizontal, alwaysBounce)
	}

	func alwaysBounceVertical(_ alwaysBounce: Bool = true) -> some View
	{
		environment(\.alwaysBounceVertical, alwaysBounce)
	}

	func initialScrollPosition(_ scrollPosition: ASCollectionViewScrollPosition?) -> some View
	{
		environment(\.initialScrollPosition, scrollPosition)
	}
}
