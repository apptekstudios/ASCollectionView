// ASCollectionView. Created by Apptek Studios 2019

import DifferenceKit
import Foundation
import UIKit

@available(iOS 13.0, *)
class ASDiffableDataSource<SectionID: Hashable>: NSObject
{
	var currentSnapshot = ASDiffableDataSourceSnapshot<SectionID>()

	func identifier(at indexPath: IndexPath) -> ASCollectionViewItemUniqueID
	{
		currentSnapshot.sections[indexPath.section].elements[indexPath.item]
	}
}

@available(iOS 13.0, *)
struct ASDiffableDataSourceSnapshot<SectionID: Hashable>
{
	var sections: [Section] = []
	struct Section
	{
		var id: SectionID
		var elements: [ASCollectionViewItemUniqueID]

		var differenceIdentifier: SectionID
		{
			id
		}

		func isContentEqual(to source: ASDiffableDataSourceSnapshot.Section) -> Bool
		{
			source.differenceIdentifier == differenceIdentifier
		}
	}

	mutating func appendSection(sectionID: SectionID, items: [ASCollectionViewItemUniqueID])
	{
		sections.append(Section(id: sectionID, elements: items))
	}
}

@available(iOS 13.0, *)
extension ASDiffableDataSourceSnapshot.Section: DifferentiableSection
{
	init<C: Swift.Collection>(source: Self, elements: C) where C.Element == ASCollectionViewItemUniqueID
	{
		self.init(id: source.differenceIdentifier, elements: Array(elements))
	}
}

@available(iOS 13.0, *)
extension ASCollectionViewItemUniqueID: Differentiable {}
