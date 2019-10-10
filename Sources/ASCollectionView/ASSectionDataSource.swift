// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

internal protocol ASSectionDataSourceProtocol
{
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	func hostController(reusingController: UIViewController?, forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
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
}

public typealias OnCellEvent<Data> = ((_ event: CellEvent<Data>) -> Void)

internal struct ASSectionDataSource<Data, DataID, Content>: ASSectionDataSourceProtocol where DataID: Hashable, Content: View
{
	var data: [Data]
	var dataIDKeyPath: KeyPath<Data, DataID>
	var onCellEvent: OnCellEvent<Data>?
	var content: (Data) -> Content
	
	func hostController(reusingController: UIViewController? = nil, forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
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
		let item = data[indexPath.item]
		onCellEvent?(.onAppear(item: item))
	}
	
	func onDisappear(_ indexPath: IndexPath)
	{
		let item = data[indexPath.item]
		onCellEvent?(.onDisappear(item: item))
	}
	
	func prefetch(_ indexPaths: [IndexPath])
	{
		let dataToPrefetch = indexPaths.map { data[$0.item] }
		onCellEvent?(.prefetchForData(data: dataToPrefetch))
	}
	
	func cancelPrefetch(_ indexPaths: [IndexPath])
	{
		let dataToCancelPrefetch = indexPaths.map { data[$0.item] }
		onCellEvent?(.cancelPrefetchForData(data: dataToCancelPrefetch))
	}
}

extension ASSectionDataSource where Data: Identifiable, DataID == Data.ID
{
	init(data: [Data], onCellEvent: OnCellEvent<Data>? = nil, content: @escaping ((Data) -> Content))
	{
		self.init(data: data, dataIDKeyPath: \.id, onCellEvent: onCellEvent, content: content)
	}
}
