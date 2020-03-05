// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
internal protocol ASSectionDataSourceProtocol
{
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	func configureCell(_ cell: ASDataSourceConfigurableCell, forItemID itemID: ASCollectionViewItemUniqueID, isSelected: Bool)
	func getTypeErasedData(for indexPath: IndexPath) -> Any?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	func removeItem(from indexPath: IndexPath)
	func insertDragItems(_ items: [UIDragItem], at indexPath: IndexPath)
	func supportsDelete(at indexPath: IndexPath) -> Bool
	func onDelete(indexPath: IndexPath, completionHandler: (Bool) -> Void)
	func getContextMenu(for indexPath: IndexPath) -> UIContextMenuConfiguration?
	func getSelfSizingSettings(context: ASSelfSizingContext) -> ASSelfSizingConfig?

	var dragEnabled: Bool { get }
	var dropEnabled: Bool { get }

	mutating func setSelfSizingConfig(config: SelfSizingConfig?)

	var estimatedRowHeight: CGFloat? { get set }
	var estimatedHeaderHeight: CGFloat? { get set }
	var estimatedFooterHeight: CGFloat? { get set }
}

@available(iOS 13.0, *)
public enum CellEvent<Data>
{
	/// Respond by starting necessary prefetch operations for this data to be displayed soon (eg. download images)
	case prefetchForData(data: [Data])

	/// Called when its no longer necessary to prefetch this data
	case cancelPrefetchForData(data: [Data])

	/// Called when an item is appearing on the screen
	case onAppear(item: Data)

	/// Called when an item is disappearing from the screen
	case onDisappear(item: Data)
}

@available(iOS 13.0, *)
public enum DragDrop<Data>
{
	case onRemoveItem(indexPath: IndexPath)
	case onAddItems(items: [Data], atIndexPath: IndexPath)
}

@available(iOS 13.0, *)
public typealias OnCellEvent<Data> = ((_ event: CellEvent<Data>) -> Void)

@available(iOS 13.0, *)
public typealias OnDragDrop<Data> = ((_ event: DragDrop<Data>) -> Void)

@available(iOS 13.0, *)
public typealias ItemProvider<Data> = ((_ item: Data) -> NSItemProvider)

@available(iOS 13.0, *)
public typealias OnSwipeToDelete<Data> = ((Data, _ completionHandler: (Bool) -> Void) -> Void)

@available(iOS 13.0, *)
public typealias ContextMenuProvider<Data> = ((_ item: Data) -> UIContextMenuConfiguration?)

@available(iOS 13.0, *)
public typealias SelfSizingConfig = ((_ context: ASSelfSizingContext) -> ASSelfSizingConfig?)

@available(iOS 13.0, *)
public struct CellContext
{
	public var isSelected: Bool
	public var isFirstInSection: Bool
	public var isLastInSection: Bool
}

@available(iOS 13.0, *)
internal struct ASSectionDataSource<DataCollection: RandomAccessCollection, DataID, Content, Container>: ASSectionDataSourceProtocol where DataID: Hashable, Content: View, Container: View, DataCollection.Index == Int
{
	typealias Data = DataCollection.Element
	var data: DataCollection
	var dataIDKeyPath: KeyPath<Data, DataID>
	var container: (Content) -> Container
	var content: (DataCollection.Element, CellContext) -> Content

	var supplementaryViews: [String: AnyView] = [:]
	var onCellEvent: OnCellEvent<DataCollection.Element>?
	var onDragDrop: OnDragDrop<DataCollection.Element>?
	var itemProvider: ItemProvider<DataCollection.Element>?
	var onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>?
	var contextMenuProvider: ContextMenuProvider<DataCollection.Element>?
	var selfSizingConfig: SelfSizingConfig?

	// Only relevant for ASTableView
	public var estimatedRowHeight: CGFloat?
	public var estimatedHeaderHeight: CGFloat?
	public var estimatedFooterHeight: CGFloat?

	var dragEnabled: Bool { onDragDrop != nil }
	var dropEnabled: Bool { onDragDrop != nil }

	func cellContext(forItemID itemID: ASCollectionViewItemUniqueID, isSelected: Bool) -> CellContext
	{
		CellContext(
			isSelected: isSelected,
			isFirstInSection: data.first?[keyPath: dataIDKeyPath].hashValue == itemID.itemIDHash,
			isLastInSection: data.last?[keyPath: dataIDKeyPath].hashValue == itemID.itemIDHash)
	}
	
	func configureCell(_ cell: ASDataSourceConfigurableCell, forItemID itemID: ASCollectionViewItemUniqueID, isSelected: Bool) {
		guard let item = data.first(where: { $0[keyPath: dataIDKeyPath].hashValue == itemID.itemIDHash }) else {
			cell.configureAsEmpty()
			return
		}
		let view = content(item, cellContext(forItemID: itemID, isSelected: isSelected))
		let content = container(view)
		
		cell.configureHostingController(forItemID: itemID, content: content)
	}

	func getTypeErasedData(for indexPath: IndexPath) -> Any?
	{
		data[safe: indexPath.item]
	}

	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	{
		data.indices.map { IndexPath(item: $0, section: sectionIndex) }
	}

	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	{
		data.map
		{
			ASCollectionViewItemUniqueID(sectionID: sectionID, itemID: $0[keyPath: dataIDKeyPath])
		}
	}

	func onAppear(_ indexPath: IndexPath)
	{
		guard let item = data[safe: indexPath.item] else { return }
		onCellEvent?(.onAppear(item: item))
	}

	func onDisappear(_ indexPath: IndexPath)
	{
		guard let item = data[safe: indexPath.item] else { return }
		onCellEvent?(.onDisappear(item: item))
	}

	func prefetch(_ indexPaths: [IndexPath])
	{
		let dataToPrefetch: [Data] = indexPaths.compactMap
		{
			data[safe: $0.item]
		}
		onCellEvent?(.prefetchForData(data: dataToPrefetch))
	}

	func cancelPrefetch(_ indexPaths: [IndexPath])
	{
		let dataToCancelPrefetch: [Data] = indexPaths.compactMap
		{
			data[safe: $0.item]
		}
		onCellEvent?(.cancelPrefetchForData(data: dataToCancelPrefetch))
	}

	func supportsDelete(at indexPath: IndexPath) -> Bool
	{
		onSwipeToDelete != nil
	}

	func onDelete(indexPath: IndexPath, completionHandler: (Bool) -> Void)
	{
		guard let item = data[safe: indexPath.item] else { return }
		onSwipeToDelete?(item, completionHandler)
	}

	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	{
		guard dragEnabled else { return nil }
		guard let item = data[safe: indexPath.item] else { return nil }

		let itemProvider: NSItemProvider = self.itemProvider?(item) ?? NSItemProvider()
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = item
		return dragItem
	}

	func removeItem(from indexPath: IndexPath)
	{
		guard data.containsIndex(indexPath.item) else { return }
		onDragDrop?(.onRemoveItem(indexPath: indexPath))
	}

	func insertDragItems(_ items: [UIDragItem], at indexPath: IndexPath)
	{
		guard dropEnabled else { return }
		let index = max(data.startIndex, min(indexPath.item, data.endIndex))
		let indexPath = IndexPath(item: index, section: indexPath.section)
		let dataItems = items.compactMap
		{ (dragItem) -> Data? in
			guard let item = dragItem.localObject as? Data else { return nil }
			return item
		}
		onDragDrop?(.onAddItems(items: dataItems, atIndexPath: indexPath))
	}
	
	func getContextMenu(for indexPath: IndexPath) -> UIContextMenuConfiguration?
	{
		guard
			let menuProvider = contextMenuProvider,
			let item = data[safe: indexPath.item]
			else { return nil }
		
		return menuProvider(item)
	}
	
	func getSelfSizingSettings(context: ASSelfSizingContext) -> ASSelfSizingConfig? {
		return selfSizingConfig?(context)
	}
}

// MARK: SELF SIZING MODIFIERS - INTERNAL

@available(iOS 13.0, *)
internal extension ASSectionDataSource
{
	mutating func setSelfSizingConfig(config: SelfSizingConfig?)
	{
		selfSizingConfig = config
	}
}
