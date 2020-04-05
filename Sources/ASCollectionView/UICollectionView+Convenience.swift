// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import UIKit

extension UICollectionView
{
	var allSections: Range<Int>?
	{
		let sectionCount = dataSource?.numberOfSections?(in: self) ?? 1
		guard sectionCount > 0 else { return nil }
		return (0 ..< sectionCount)
	}

	func allIndexPaths(inSection section: Int) -> [IndexPath]
	{
		guard let itemCount = dataSource?.collectionView(self, numberOfItemsInSection: section), itemCount > 0 else { return [] }
		return (0 ..< itemCount).map
		{ item in
			IndexPath(item: item, section: section)
		}
	}

	func allIndexPaths() -> [IndexPath]
	{
		guard let allSections = allSections else { return [] }
		return allSections.flatMap
		{ section -> [IndexPath] in
			allIndexPaths(inSection: section)
		}
	}

	func allIndexPaths(after afterIndexPath: IndexPath) -> [IndexPath]
	{
		guard let sectionCount = dataSource?.numberOfSections?(in: self), sectionCount > 0 else { return [] }
		return (afterIndexPath.section ..< sectionCount).flatMap
		{ section -> [IndexPath] in
			guard let itemCount = dataSource?.collectionView(self, numberOfItemsInSection: section), itemCount > 0 else { return [] }
			let startIndex: Int
			if section == afterIndexPath.section
			{
				startIndex = afterIndexPath.item + 1
			}
			else
			{
				startIndex = 0
			}
			guard startIndex < itemCount else { return [] }
			return (startIndex ..< itemCount).map
			{ item in
				IndexPath(item: item, section: section)
			}
		}
	}

	var firstIndexPath: IndexPath?
	{
		guard
			let sectionCount = dataSource?.numberOfSections?(in: self), sectionCount > 0,
			let itemCount = dataSource?.collectionView(self, numberOfItemsInSection: 0), itemCount > 0
		else { return nil }
		return IndexPath(item: 0, section: 0)
	}

	var lastIndexPath: IndexPath?
	{
		guard
			let sectionCount = dataSource?.numberOfSections?(in: self), sectionCount > 0,
			let itemCount = dataSource?.collectionView(self, numberOfItemsInSection: sectionCount - 1), itemCount > 0
		else { return nil }
		return IndexPath(item: itemCount - 1, section: sectionCount - 1)
	}
}

public enum Boundary: CaseIterable
{
	case left
	case right
	case top
	case bottom
}
