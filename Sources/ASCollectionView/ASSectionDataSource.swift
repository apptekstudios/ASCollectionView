// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

internal protocol ASSectionDataSourceProtocol
{
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	func hostController(reusingController: ASHostingControllerProtocol?, forItemID itemID: ASCollectionViewItemUniqueID) -> ASHostingControllerProtocol?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	func removeItem(from indexPath: IndexPath)
	func insertDragItems(_ items: [UIDragItem], at indexPath: IndexPath)
	var dragEnabled: Bool { get set }
	var dropEnabled: Bool { get set }
}

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
	
	/// Called when an item should be moved
	case onRemoveItem(indexPath: IndexPath)
	case onAddItems(items: [Data], atIndexPath: IndexPath)
}

public typealias OnCellEvent<Data> = ((_ event: CellEvent<Data>) -> Void)

internal struct ASSectionDataSource<Data, DataID, Content>: ASSectionDataSourceProtocol where DataID: Hashable, Content: View
{
	var data: [Data]
	var dataIDKeyPath: KeyPath<Data, DataID>
	var onCellEvent: OnCellEvent<Data>?
	var content: (Data) -> Content
	
	var dragEnabled: Bool = false
	var dropEnabled: Bool = false
	
	func hostController(reusingController: ASHostingControllerProtocol? = nil, forItemID itemID: ASCollectionViewItemUniqueID) -> ASHostingControllerProtocol?
	{
		guard let item = data.first(where: { $0[keyPath: dataIDKeyPath].hashValue == itemID.itemIDHash }) else { return nil }
		let view = content(item)
		
		if let existingHC = reusingController as? ASHostingController<Content>
		{
			existingHC.setView(view)
			return existingHC
		}
		else
		{
			let newHC = ASHostingController<Content>(view)
			return newHC
		}
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
        guard indexPath.item < data.endIndex else { return }
		let item = data[indexPath.item]
		onCellEvent?(.onAppear(item: item))
	}
	
	func onDisappear(_ indexPath: IndexPath)
	{
        guard indexPath.item < data.endIndex else { return }
		let item = data[indexPath.item]
		onCellEvent?(.onDisappear(item: item))
	}
	
	func prefetch(_ indexPaths: [IndexPath])
	{
        let dataToPrefetch: [Data] = indexPaths.compactMap {
            guard $0.item < data.endIndex else { return nil }
            return data[$0.item]
        }
		onCellEvent?(.prefetchForData(data: dataToPrefetch))
	}
	
	func cancelPrefetch(_ indexPaths: [IndexPath])
	{
        let dataToCancelPrefetch: [Data] = indexPaths.compactMap {
            guard $0.item < data.endIndex else { return nil }
            return data[$0.item]
        }
		onCellEvent?(.cancelPrefetchForData(data: dataToCancelPrefetch))
	}
	
	func getDragItem(for indexPath: IndexPath) -> UIDragItem? {
		guard dragEnabled else { return nil }
		let dragItem = UIDragItem(itemProvider: NSItemProvider())
		dragItem.localObject = data[indexPath.item]
		return dragItem
	}
	
	func removeItem(from indexPath: IndexPath) {
		guard indexPath.item < data.endIndex else { return }
		onCellEvent?(.onRemoveItem(indexPath: indexPath))
	}
	
	func insertDragItems(_ items: [UIDragItem], at indexPath: IndexPath) {
		guard dropEnabled else { return }
		let index = IndexPath(item: min(indexPath.item, data.endIndex), section: indexPath.section)
		let dataItems = items.compactMap { (dragItem) -> Data? in
			guard let item = dragItem.localObject as? Data else { return nil }
			return item
		}
		onCellEvent?(.onAddItems(items: dataItems, atIndexPath: index))
	}
}

extension ASSectionDataSource where Data: Identifiable, DataID == Data.ID
{
	init(data: [Data], onCellEvent: OnCellEvent<Data>? = nil, content: @escaping ((Data) -> Content))
	{
		self.init(data: data, dataIDKeyPath: \.id, onCellEvent: onCellEvent, content: content)
	}
}
