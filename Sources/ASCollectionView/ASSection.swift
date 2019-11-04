// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

public struct ASCollectionViewStaticContent: Identifiable
{
	public var id: Int
	public var view: AnyView
}

public struct ASCollectionViewItemUniqueID: Hashable
{
	var sectionIDHash: Int
	var itemIDHash: Int
	init<SectionID: Hashable, ItemID: Hashable>(sectionID: SectionID, itemID: ItemID)
	{
		sectionIDHash = sectionID.hashValue
		itemIDHash = itemID.hashValue
	}
}

public struct ASCollectionViewSection<SectionID: Hashable>: Hashable
{
	public var id: SectionID

	private var supplementaryViews: [String: AnyView] = [:]

	internal var dataSource: ASSectionDataSourceProtocol

	public var itemIDs: [ASCollectionViewItemUniqueID]
	{
		dataSource.getUniqueItemIDs(withSectionID: id)
	}

	var estimatedItemSize: CGSize?

	/**
	 Initializes a  section with data

	 - Parameters:
	 	- id: The id for this section
	 	- data: The data to display in the section. This initialiser expects data that conforms to 'Identifiable'
	 	- dataID: The keypath to a hashable identifier of each data item
	 	- estimatedItemSize: (Optional) Provide an estimated item size to aid in calculating the layout
	 	- onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
	 - onDragDrop: Define this closure to enable drag/drop and respond to events (default is nil: drag/drop disabled)
	 	- contentBuilder: A closure returning a SwiftUI view for the given data item
	 */
	public init<Data, DataID: Hashable, Content: View>(
		id: SectionID,
		data: [Data],
		dataID dataIDKeyPath: KeyPath<Data, DataID>,
		estimatedItemSize: CGSize? = nil,
		onCellEvent: OnCellEvent<Data>? = nil,
		onDragDrop: OnDragDrop<Data>? = nil,
		@ViewBuilder contentBuilder: @escaping ((Data, CellContext) -> Content))
	{
		self.id = id
		self.estimatedItemSize = estimatedItemSize
		dataSource = ASSectionDataSource<Data, DataID, Content>(
			data: data,
			dataIDKeyPath: dataIDKeyPath,
			onCellEvent: onCellEvent,
			onDragDrop: onDragDrop,
			content: contentBuilder)
	}

	public func hash(into hasher: inout Hasher)
	{
		hasher.combine(id)
	}

	public static func ==(lhs: ASCollectionViewSection<SectionID>, rhs: ASCollectionViewSection<SectionID>) -> Bool
	{
		lhs.id == rhs.id
	}
}

// MARK: SUPPLEMENTARY VIEWS - INTERNAL

internal extension ASCollectionViewSection
{
	mutating func setHeaderView<Content: View>(_ view: Content?)
	{
		setSupplementaryView(view, ofKind: UICollectionView.elementKindSectionHeader)
	}

	mutating func setFooterView<Content: View>(_ view: Content?)
	{
		setSupplementaryView(view, ofKind: UICollectionView.elementKindSectionFooter)
	}

	mutating func setSupplementaryView<Content: View>(_ view: Content?, ofKind kind: String)
	{
		guard let view = view else
		{
			supplementaryViews.removeValue(forKey: kind)
			return
		}

		supplementaryViews[kind] = AnyView(view)
	}

	var supplementaryKinds: Set<String>
	{
		Set(supplementaryViews.keys)
	}

	func supplementary(ofKind kind: String) -> AnyView?
	{
		supplementaryViews[kind]
	}
}

// MARK: SUPPLEMENTARY VIEWS - PUBLIC MODIFIERS

public extension ASCollectionViewSection
{
	func sectionHeader<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		section.setHeaderView(content())
		return section
	}

	func sectionFooter<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		section.setFooterView(content())
		return section
	}

	func sectionSupplementary<Content: View>(ofKind kind: String, content: () -> Content?) -> Self
	{
		var section = self
		section.setSupplementaryView(content(), ofKind: kind)
		return section
	}
}

// MARK: STATIC CONTENT SECTION

public extension ASCollectionViewSection
{
	/**
	 Initializes a section with static content

	 - Parameters:
	 - id: The id for this section
	 - content: A closure returning a number of SwiftUI views to display in the collection view
	 */
	init(id: SectionID, @ViewArrayBuilder content: () -> [AnyView])
	{
		self.id = id
		dataSource = ASSectionDataSource<ASCollectionViewStaticContent, ASCollectionViewStaticContent.ID, AnyView>(
			data: content().enumerated().map
			{
				ASCollectionViewStaticContent(id: $0.offset, view: $0.element)
			},
			dataIDKeyPath: \.id,
			content: { staticContent, _ in staticContent.view })
	}

	/**
	 Initializes a section with a single view

	 - Parameters:
	 - id: The id for this section
	 - content: A single SwiftUI views to display in the collection view
	 */
	init<Content: View>(id: SectionID, content: () -> Content)
	{
		self.id = id
		dataSource = ASSectionDataSource<ASCollectionViewStaticContent, ASCollectionViewStaticContent.ID, AnyView>(
			data: [ASCollectionViewStaticContent(id: 0, view: AnyView(content()))],
			dataIDKeyPath: \.id,
			content: { staticContent, _ in staticContent.view })
	}
}

// MARK: IDENTIFIABLE DATA SECTION

public extension ASCollectionViewSection
{
	/**
	 Initializes a  section with identifiable data

	 - Parameters:
	 	- id: The id for this section
	 	- data: The data to display in the section. This initialiser expects data that conforms to 'Identifiable'
	 	- estimatedItemSize: (Optional) Provide an estimated item size to aid in calculating the layout
	 	- onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
	 - onDragDrop: Define this closure to enable drag/drop and respond to events (default is nil: drag/drop disabled)
	 	- contentBuilder: A closure returning a SwiftUI view for the given data item
	 */
	@inlinable init<Content: View, Data: Identifiable>(
		id: SectionID,
		data: [Data],
		estimatedItemSize: CGSize? = nil,
		onCellEvent: OnCellEvent<Data>? = nil,
		onDragDrop: OnDragDrop<Data>? = nil,
		@ViewBuilder contentBuilder: @escaping ((Data, CellContext) -> Content))
	{
		self.init(id: id, data: data, dataID: \.id, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, onDragDrop: onDragDrop, contentBuilder: contentBuilder)
	}
}
