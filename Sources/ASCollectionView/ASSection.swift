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

	public var header: AnyView?
	public var dataSource: ASSectionDataSourceProtocol

	public var itemIDs: [ASCollectionViewItemUniqueID]
	{
		dataSource.getUniqueItemIDs(withSectionID: id)
	}

	public func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	{
		dataSource.getIndexPaths(withSectionIndex: sectionIndex)
	}

	func hostController(reusingController: UIViewController? = nil, forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
	{
		dataSource.hostController(reusingController: reusingController, forItemID: itemID)
	}

	public func onAppear(_ indexPath: IndexPath)
	{
		dataSource.onAppear(indexPath)
	}

	public func onDisappear(_ indexPath: IndexPath)
	{
		dataSource.onDisappear(indexPath)
	}

	func prefetch(_ indexPaths: [IndexPath])
	{
		dataSource.prefetch(indexPaths)
	}

	func cancelPrefetch(_ indexPaths: [IndexPath])
	{
		dataSource.cancelPrefetch(indexPaths)
	}

	var estimatedItemSize: CGSize?

	public init<Data, DataID: Hashable, Content: View>(id: SectionID,
	                                                   data: [Data],
	                                                   dataID dataIDKeyPath: KeyPath<Data, DataID>,
	                                                   estimatedItemSize: CGSize? = nil,
	                                                   onCellEvent: ASSectionDataSource<Data, DataID, Content>.OnCellEvent? = nil,
	                                                   @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.id = id
		self.estimatedItemSize = estimatedItemSize
		dataSource = ASSectionDataSource<Data, DataID, Content>(data: data,
		                                                                      dataIDKeyPath: dataIDKeyPath,
		                                                                      onCellEvent: onCellEvent,
		                                                                      content: contentBuilder)
	}

	public init<Header: View, Data, DataID: Hashable, Content: View>(id: SectionID,
	                                                                 header: Header,
	                                                                 data: [Data],
	                                                                 dataID dataIDKeyPath: KeyPath<Data, DataID>,
	                                                                 estimatedItemSize: CGSize? = nil,
	                                                                 onCellEvent: ASSectionDataSource<Data, DataID, Content>.OnCellEvent? = nil,
	                                                                 @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.init(id: id,
		          data: data,
		          dataID: dataIDKeyPath,
		          estimatedItemSize: estimatedItemSize,
		          onCellEvent: onCellEvent,
		          contentBuilder: contentBuilder)
		self.header = AnyView(header)
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

// MARK: STATIC CONTENT SECTION

public extension ASCollectionViewSection
{
	init(id: SectionID, @ViewArrayBuilder content: () -> [AnyView])
	{
		self.id = id
		dataSource = ASSectionDataSource<ASCollectionViewStaticContent, ASCollectionViewStaticContent.ID, AnyView>(data: content().enumerated().map
			{
				ASCollectionViewStaticContent(id: $0.offset, view: $0.element)
			},
		                                                                                                                         content: { $0.view })
	}

	init<Header: View>(id: SectionID, header: Header, @ViewArrayBuilder content: () -> [AnyView])
	{
		self.init(id: id, content: content)
		self.header = AnyView(header)
	}
}

// MARK: IDENTIFIABLE DATA SECTION

public extension ASCollectionViewSection
{
	@inlinable init<Content: View, Data: Identifiable>(id: SectionID, data: [Data], estimatedItemSize: CGSize? = nil, onCellEvent: ASSectionDataSource<Data, Data.ID, Content>.OnCellEvent? = nil, @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.init(id: id, data: data, dataID: \.id, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: contentBuilder)
	}

	init<Content: View, Header: View, Data: Identifiable>(id: SectionID, header: Header, data: [Data], estimatedItemSize: CGSize? = nil, onCellEvent: ASSectionDataSource<Data, Data.ID, Content>.OnCellEvent? = nil, @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.init(id: id, header: AnyView(header), data: data, dataID: \.id, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: contentBuilder)
	}
}
