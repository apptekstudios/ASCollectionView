// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

public protocol ASSectionDataSourceProtocol
{
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	func hostController(reusingController: UIViewController?, forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
}

public struct ASSectionDataSource<Data, DataID, Content>: ASSectionDataSourceProtocol where DataID: Hashable, Content: View
{
	public var data: [Data]
	public var dataIDKeyPath: KeyPath<Data, DataID>
	public var onCellEvent: OnCellEvent?
	public var content: (Data) -> Content
	
	public func hostController(reusingController: UIViewController? = nil, forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
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
	
	public func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	{
		data.indices.map { IndexPath(item: $0, section: sectionIndex) }
	}
	
	public func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	{
		data.map
			{
				ASCollectionViewItemUniqueID(sectionID: sectionID, itemID: $0[keyPath: dataIDKeyPath])
		}
	}
	
	public func onAppear(_ indexPath: IndexPath)
	{
		let item = data[indexPath.item]
		onCellEvent?(.onAppear(item: item))
	}
	
	public func onDisappear(_ indexPath: IndexPath)
	{
		let item = data[indexPath.item]
		onCellEvent?(.onDisappear(item: item))
	}
	
	public func prefetch(_ indexPaths: [IndexPath])
	{
		let dataToPrefetch = indexPaths.map { data[$0.item] }
		onCellEvent?(.prefetchForData(data: dataToPrefetch))
	}
	
	public func cancelPrefetch(_ indexPaths: [IndexPath])
	{
		let dataToCancelPrefetch = indexPaths.map { data[$0.item] }
		onCellEvent?(.cancelPrefetchForData(data: dataToCancelPrefetch))
	}
	
	public enum CellEvent
	{
		case prefetchForData(data: [Data])
		case cancelPrefetchForData(data: [Data])
		case onAppear(item: Data)
		case onDisappear(item: Data)
	}
	
	public typealias OnCellEvent = ((_ event: CellEvent) -> Void)
}

extension ASSectionDataSource where Data: Identifiable, DataID == Data.ID
{
	init(data: [Data], onCellEvent: OnCellEvent? = nil, content: @escaping ((Data) -> Content))
	{
		self.init(data: data, dataIDKeyPath: \.id, onCellEvent: onCellEvent, content: content)
	}
}
