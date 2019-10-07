// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

struct EnvironmentKeyScrollIndicatorsEnabled: EnvironmentKey
{
	static let defaultValue: Bool = true
}

struct EnvironmentKeyTableViewSeparatorsEnabled: EnvironmentKey
{
	static let defaultValue: Bool = true
}

struct EnvironmentKeyTableViewOnReachedBottom: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

public extension EnvironmentValues
{
	var scrollIndicatorsEnabled: Bool
	{
		get { return self[EnvironmentKeyScrollIndicatorsEnabled.self] }
		set { self[EnvironmentKeyScrollIndicatorsEnabled.self] = newValue }
	}

	var tableViewSeparatorsEnabled: Bool
	{
		get { return self[EnvironmentKeyTableViewSeparatorsEnabled.self] }
		set { self[EnvironmentKeyTableViewSeparatorsEnabled.self] = newValue }
	}

	var tableViewOnReachedBottom: () -> Void
	{
		get { return self[EnvironmentKeyTableViewOnReachedBottom.self] }
		set { self[EnvironmentKeyTableViewOnReachedBottom.self] = newValue }
	}
}

public extension View
{
	func scrollIndicatorsEnabled(_ enabled: Bool) -> some View
	{
		environment(\.scrollIndicatorsEnabled, enabled)
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
