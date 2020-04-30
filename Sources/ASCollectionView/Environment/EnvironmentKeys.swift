// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: Internal Key Definitions

@available(iOS 13.0, *)
struct EnvironmentKeyInvalidateCellLayout: EnvironmentKey
{
	static let defaultValue: ((_ animated: Bool) -> Void)? = nil
}

struct EnvironmentKeyTableViewScrollToCell: EnvironmentKey
{
	static let defaultValue: ((UITableView.ScrollPosition) -> Void)? = nil
}

struct EnvironmentKeyCollectionViewScrollToCell: EnvironmentKey
{
	static let defaultValue: ((UICollectionView.ScrollPosition) -> Void)? = nil
}

// MARK: Internal Helpers

@available(iOS 13.0, *)
public extension EnvironmentValues
{
	var invalidateCellLayout: ((_ animated: Bool) -> Void)?
	{
		get { self[EnvironmentKeyInvalidateCellLayout.self] }
		set { self[EnvironmentKeyInvalidateCellLayout.self] = newValue }
	}

	var tableViewScrollToCell: ((UITableView.ScrollPosition) -> Void)?
	{
		get { self[EnvironmentKeyTableViewScrollToCell.self] }
		set { self[EnvironmentKeyTableViewScrollToCell.self] = newValue }
	}

	var collectionViewScrollToCell: ((UICollectionView.ScrollPosition) -> Void)?
	{
		get { self[EnvironmentKeyCollectionViewScrollToCell.self] }
		set { self[EnvironmentKeyCollectionViewScrollToCell.self] = newValue }
	}
}
