// ASCollectionView. Created by Apptek Studios 2019

import DifferenceKit
import Foundation
import UIKit

@available(iOS 13.0, *)
class ASDiffableDataSource<SectionID: Hashable>: NSObject
{
	public internal(set) var currentSnapshot = ASDiffableDataSourceSnapshot<SectionID>()

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
		sections.enumerated().forEach
		{ sectionIndex, section in
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
		items.forEach
		{ item in
			guard let position = itemPositionMap[item] else { return }
			sections[position.sectionIndex].elements[position.itemIndex].shouldReload = true
		}
	}

	mutating func moveItem(fromIndexPath: IndexPath, toIndexPath: IndexPath)
	{
		guard sections.containsIndex(fromIndexPath.section), sections.containsIndex(toIndexPath.section) else { return }
		if fromIndexPath.section == toIndexPath.section
		{
			let item = sections[fromIndexPath.section].elements.remove(at: fromIndexPath.item)
			sections[toIndexPath.section].elements.insert(item, at: toIndexPath.item)
		}
		else
		{
			let item = sections[fromIndexPath.section].elements.remove(at: fromIndexPath.item)
			sections[toIndexPath.section].elements.insert(item, at: toIndexPath.item)
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
		var shouldReload: Bool

		init(id: ASCollectionViewItemUniqueID, shouldReload: Bool = false)
		{
			differenceIdentifier = id
			self.shouldReload = shouldReload
		}

		func isContentEqual(to source: Item) -> Bool
		{
			!shouldReload && differenceIdentifier == source.differenceIdentifier
		}
	}
}

@available(iOS 13.0, *)
extension ASDiffableDataSourceSnapshot.Section
{
	init(id: SectionID, elements: [ASCollectionViewItemUniqueID], shouldReloadElements: Bool = false)
	{
		self.id = id
		self.elements = elements.map { ASDiffableDataSourceSnapshot.Item(id: $0, shouldReload: shouldReloadElements) }
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
