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
		currentSnapshot.sections[indexPath.section].elements[indexPath.item].differenceIdentifier
	}
}

@available(iOS 13.0, *)
struct ASDiffableDataSourceSnapshot<SectionID: Hashable>
{
	private(set) var sections: [Section]
	private(set) var itemPositionMap: [ASCollectionViewItemUniqueID: ItemPosition] = [:]

	init(sections: [Section] = [])
	{
		self.sections = sections
		sections.enumerated().forEach { sectionIndex, section in
			section.elements.enumerated().forEach { itemIndex, item in itemPositionMap[item.differenceIdentifier] = ItemPosition(itemIndex: itemIndex, sectionIndex: sectionIndex) }
		}
	}

	mutating func appendSection(sectionID: SectionID, items: [ASCollectionViewItemUniqueID])
	{
		let newSection = Section(id: sectionID, elements: items)
		sections.append(newSection)
		newSection.elements.enumerated().forEach { itemIndex, item in itemPositionMap[item.differenceIdentifier] = ItemPosition(itemIndex: itemIndex, sectionIndex: sections.endIndex - 1) }
	}

	mutating func removeItems(fromSectionIndex sectionIndex: Int, atOffsets offsets: IndexSet)
	{
		guard sections.containsIndex(sectionIndex) else { return }
		sections[sectionIndex].elements.remove(atOffsets: offsets)
	}

	mutating func insertItems(_ items: [ASCollectionViewItemUniqueID], atSectionIndex sectionIndex: Int, atOffset offset: Int)
	{
		guard sections.containsIndex(sectionIndex) else { return }
		sections[sectionIndex].elements.insert(contentsOf: items.map { Item(id: $0) }, at: offset)
	}

	mutating func reloadItems(items: Set<ASCollectionViewItemUniqueID>)
	{
		items.forEach { item in
			guard let position = itemPositionMap[item] else { return }
			sections[position.sectionIndex].elements[position.itemIndex].isReloaded = true
		}
	}

	struct ItemPosition
	{
		var itemIndex: Int
		var sectionIndex: Int
	}

	struct Section
	{
		var id: SectionID
		var elements: [Item]

		var differenceIdentifier: SectionID
		{
			id
		}

		func isContentEqual(to source: ASDiffableDataSourceSnapshot.Section) -> Bool
		{
			source.differenceIdentifier == differenceIdentifier
		}
	}

	struct Item: Differentiable
	{
		var differenceIdentifier: ASCollectionViewItemUniqueID
		var isReloaded: Bool

		init(id: ASCollectionViewItemUniqueID, isReloaded: Bool)
		{
			differenceIdentifier = id
			self.isReloaded = isReloaded
		}

		init(id: ASCollectionViewItemUniqueID)
		{
			self.init(id: id, isReloaded: false)
		}

		func isContentEqual(to source: Item) -> Bool
		{
			!isReloaded && differenceIdentifier == source.differenceIdentifier
		}
	}
}

@available(iOS 13.0, *)
extension ASDiffableDataSourceSnapshot.Section
{
	init(id: SectionID, elements: [ASCollectionViewItemUniqueID])
	{
		self.id = id
		self.elements = elements.map { ASDiffableDataSourceSnapshot.Item(id: $0) }
	}
}

@available(iOS 13.0, *)
extension ASDiffableDataSourceSnapshot.Section: DifferentiableSection
{
	init<C: Swift.Collection>(source: Self, elements: C) where C.Element == ASDiffableDataSourceSnapshot.Item
	{
		self.init(id: source.differenceIdentifier, elements: Array(elements))
	}
}

@available(iOS 13.0, *)
extension ASCollectionViewItemUniqueID: Differentiable {}
