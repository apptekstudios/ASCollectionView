// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: Internal Key Definitions

@available(iOS 13.0, *)
struct EnvironmentKeyInvalidateCellLayout: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

// MARK: Internal Helpers

@available(iOS 13.0, *)
public extension EnvironmentValues
{
	var invalidateCellLayout: () -> Void
	{
		get { self[EnvironmentKeyInvalidateCellLayout.self] }
		set { self[EnvironmentKeyInvalidateCellLayout.self] = newValue }
	}
}
