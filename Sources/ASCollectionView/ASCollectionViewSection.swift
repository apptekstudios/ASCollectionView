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

public protocol ASCollectionViewSectionDataSourceProtocol
{
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	func hostController(reusingController: UIViewController?, forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
}

public struct ASCollectionViewSectionDataSource<Data, DataID, Content>: ASCollectionViewSectionDataSourceProtocol where DataID: Hashable, Content: View
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

extension ASCollectionViewSectionDataSource where Data: Identifiable, DataID == Data.ID
{
	init(data: [Data], onCellEvent: OnCellEvent? = nil, content: @escaping ((Data) -> Content))
	{
		self.init(data: data, dataIDKeyPath: \.id, onCellEvent: onCellEvent, content: content)
	}
}

public struct ASCollectionViewSection<SectionID: Hashable>: Hashable
{
	public var id: SectionID

	public var header: AnyView?
	public var dataSource: ASCollectionViewSectionDataSourceProtocol

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
	                                                   onCellEvent: ASCollectionViewSectionDataSource<Data, DataID, Content>.OnCellEvent? = nil,
	                                                   @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.id = id
		self.estimatedItemSize = estimatedItemSize
		dataSource = ASCollectionViewSectionDataSource<Data, DataID, Content>(data: data,
		                                                                      dataIDKeyPath: dataIDKeyPath,
		                                                                      onCellEvent: onCellEvent,
		                                                                      content: contentBuilder)
	}

	public init<Header: View, Data, DataID: Hashable, Content: View>(id: SectionID,
	                                                                 header: Header,
	                                                                 data: [Data],
	                                                                 dataID dataIDKeyPath: KeyPath<Data, DataID>,
	                                                                 estimatedItemSize: CGSize? = nil,
	                                                                 onCellEvent: ASCollectionViewSectionDataSource<Data, DataID, Content>.OnCellEvent? = nil,
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
		dataSource = ASCollectionViewSectionDataSource<ASCollectionViewStaticContent, ASCollectionViewStaticContent.ID, AnyView>(data: content().enumerated().map
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
	@inlinable init<Content: View, Data: Identifiable>(id: SectionID, data: [Data], estimatedItemSize: CGSize? = nil, onCellEvent: ASCollectionViewSectionDataSource<Data, Data.ID, Content>.OnCellEvent? = nil, @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.init(id: id, data: data, dataID: \.id, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: contentBuilder)
	}

	init<Content: View, Header: View, Data: Identifiable>(id: SectionID, header: Header, data: [Data], estimatedItemSize: CGSize? = nil, onCellEvent: ASCollectionViewSectionDataSource<Data, Data.ID, Content>.OnCellEvent? = nil, @ViewBuilder contentBuilder: @escaping ((Data) -> Content))
	{
		self.init(id: id, header: AnyView(header), data: data, dataID: \.id, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: contentBuilder)
	}
}

struct ASHostingControllerModifier: ViewModifier
{
	var invalidateCellLayout: (() -> Void) = {}
	func body(content: Content) -> some View
	{
		content
			.environment(\.invalidateCellLayout, invalidateCellLayout)
	}
}

struct EnvironmentKeyInvalidateCellLayout: EnvironmentKey
{
	static let defaultValue: (() -> Void) = {}
}

public extension EnvironmentValues
{
	var invalidateCellLayout: () -> Void
	{
		get { return self[EnvironmentKeyInvalidateCellLayout.self] }
		set { self[EnvironmentKeyInvalidateCellLayout.self] = newValue }
	}
}

protocol ASHostingControllerProtocol
{
	func applyModifier(_ modifier: ASHostingControllerModifier)
	func sizeThatFits(in size: CGSize) -> CGSize
}

class ASHostingController<ViewType: View>: UIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>, ASHostingControllerProtocol
{
	init(_ view: ViewType)
	{
		hostedView = view
		super.init(rootView: view.modifier(modifier))
	}

	var hostedView: ViewType
	var modifier: ASHostingControllerModifier = ASHostingControllerModifier()
	{
		didSet
		{
			rootView = hostedView.modifier(modifier)
		}
	}

	func setView(_ view: ViewType)
	{
		hostedView = view
		rootView = hostedView.modifier(modifier)
	}

	func applyModifier(_ modifier: ASHostingControllerModifier)
	{
		self.modifier = modifier
	}

	@objc dynamic required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}
