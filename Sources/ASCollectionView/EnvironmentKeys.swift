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

	func tableViewReachedBottom(_ onReachedBottom: @escaping (() -> Void)) -> some View
	{
		environment(\.tableViewOnReachedBottom, onReachedBottom)
	}
}
