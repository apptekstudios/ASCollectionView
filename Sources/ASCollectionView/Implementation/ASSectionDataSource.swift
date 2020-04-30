// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
internal protocol ASSectionDataSourceProtocol
{
	var endIndex: Int { get }
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getItemID<SectionID: Hashable>(for index: Int, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	func updateOrCreateHostController(forItemID itemID: ASCollectionViewItemUniqueID, existingHC: ASHostingControllerProtocol?) -> ASHostingControllerProtocol?
	func update(_ hc: ASHostingControllerProtocol, forItemID itemID: ASCollectionViewItemUniqueID)
	func updateOrCreateHostController(forSupplementaryKind supplementaryKind: String, existingHC: ASHostingControllerProtocol?) -> ASHostingControllerProtocol?
	var supplementaryViews: [String: AnyView] { get set }
	func getTypeErasedData(for indexPath: IndexPath) -> Any?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
	func willAcceptDropItem(from dragItem: UIDragItem) -> Bool
	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	func getItemID<SectionID: Hashable>(for dragItem: UIDragItem, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	func applyRemove(atOffsets offsets: IndexSet)
	func applyInsert(items: [UIDragItem], at index: Int)
	func supportsDelete(at indexPath: IndexPath) -> Bool
	func onDelete(indexPath: IndexPath, completionHandler: (Bool) -> Void)
	func getContextMenu(for indexPath: IndexPath) -> UIContextMenuConfiguration?
	func getSelfSizingSettings(context: ASSelfSizingContext) -> ASSelfSizingConfig?

	func isSelected(index: Int) -> Bool
	func updateSelection(_ indices: Set<Int>)
	func shouldSelect(_ indexPath: IndexPath) -> Bool
	func shouldDeselect(_ indexPath: IndexPath) -> Bool

	var dragEnabled: Bool { get }
	var dropEnabled: Bool { get }
	var reorderingEnabled: Bool { get }

	mutating func setSelfSizingConfig(config: @escaping SelfSizingConfig)
}

@available(iOS 13.0, *)
protocol ASDataSourceConfigurableCell
{
	var hostingController: ASHostingControllerProtocol? { get set }
}

@available(iOS 13.0, *)
internal struct ASSectionDataSource<DataCollection: RandomAccessCollection, DataID, Content, Container>: ASSectionDataSourceProtocol where DataID: Hashable, Content: View, Container: View, DataCollection.Index == Int
{
	typealias Data = DataCollection.Element
	var data: DataCollection
	var dataIDKeyPath: KeyPath<Data, DataID>
	var container: (Content) -> Container
	var content: (DataCollection.Element, ASCellContext) -> Content

	var selectedItems: Binding<Set<Int>>?
	var shouldAllowSelection: ((_ index: Int) -> Bool)?
	var shouldAllowDeselection: ((_ index: Int) -> Bool)?

	var onCellEvent: OnCellEvent<DataCollection.Element>?
	var dragDropConfig: ASDragDropConfig<DataCollection.Element>
	var shouldAllowSwipeToDelete: ShouldAllowSwipeToDelete?
	var onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>?
	var contextMenuProvider: ContextMenuProvider<DataCollection.Element>?
	var selfSizingConfig: (SelfSizingConfig)?

	var supplementaryViews: [String: AnyView] = [:]

	var dragEnabled: Bool { dragDropConfig.dragEnabled }
	var dropEnabled: Bool { dragDropConfig.dropEnabled }
	var reorderingEnabled: Bool { dragDropConfig.reorderingEnabled }

	var endIndex: Int { data.endIndex }

	func getIndex(of itemID: ASCollectionViewItemUniqueID) -> Int?
	{
		data.firstIndex(where: { $0[keyPath: dataIDKeyPath].hashValue == itemID.itemIDHash })
	}

	func cellContext(for index: Int) -> ASCellContext
	{
		ASCellContext(
			isSelected: isSelected(index: index),
			index: index,
			isFirstInSection: index == data.startIndex,
			isLastInSection: index == data.endIndex - 1)
	}

	func updateOrCreateHostController(forItemID itemID: ASCollectionViewItemUniqueID, existingHC: ASHostingControllerProtocol?) -> ASHostingControllerProtocol?
	{
		guard let content = getContent(forItemID: itemID) else { return nil }
		return updateOrCreateHostController(content: content, existingHC: existingHC)
	}

	func update(_ hc: ASHostingControllerProtocol, forItemID itemID: ASCollectionViewItemUniqueID)
	{
		guard let content = getContent(forItemID: itemID) else { return }
		update(hc, withContent: content)
	}

	func updateOrCreateHostController(forSupplementaryKind supplementaryKind: String, existingHC: ASHostingControllerProtocol?) -> ASHostingControllerProtocol?
	{
		guard let content = supplementaryViews[supplementaryKind] else { return nil }
		return updateOrCreateHostController(content: content, existingHC: existingHC)
	}

	private func updateOrCreateHostController<Wrapped: View>(content: Wrapped, existingHC: ASHostingControllerProtocol?) -> ASHostingControllerProtocol
	{
		if let hc = (existingHC as? ASHostingController<Wrapped>)
		{
			hc.setView(content)
			hc.disableSwiftUIDropInteraction = dropEnabled
			hc.disableSwiftUIDragInteraction = dragEnabled
			return hc
		}
		else
		{
			let newHC = ASHostingController(content)
			newHC.disableSwiftUIDropInteraction = dropEnabled
			newHC.disableSwiftUIDragInteraction = dragEnabled
			return newHC
		}
	}

	private func update<Wrapped: View>(_ hc: ASHostingControllerProtocol, withContent content: Wrapped)
	{
		guard let hc = hc as? ASHostingController<Wrapped> else { return }
		hc.setView(content)
	}

	func getContent(forItemID itemID: ASCollectionViewItemUniqueID) -> Container?
	{
		guard let itemIndex = getIndex(of: itemID) else { return nil }
		let item = data[itemIndex]
		let view = content(item, cellContext(for: itemIndex))
		return container(view)
	}

	func getTypeErasedData(for indexPath: IndexPath) -> Any?
	{
		data[safe: indexPath.item]
	}

	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	{
		data.indices.map { IndexPath(item: $0, section: sectionIndex) }
	}

	func getItemID<SectionID: Hashable>(for index: Int, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	{
		data[safe: index].map { getItemID(for: $0, withSectionID: sectionID) }
	}

	func getItemID<SectionID: Hashable>(for item: Data, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID
	{
		ASCollectionViewItemUniqueID(sectionID: sectionID, itemID: item[keyPath: dataIDKeyPath])
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
		guard onSwipeToDelete != nil else { return false }
		return shouldAllowSwipeToDelete?(indexPath.item) ?? true
	}

	func onDelete(indexPath: IndexPath, completionHandler: (Bool) -> Void)
	{
		guard let item = data[safe: indexPath.item] else { return }
		onSwipeToDelete?(indexPath.item, item, completionHandler)
	}

	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	{
		guard dragEnabled else { return nil }
		guard let item = data[safe: indexPath.item] else { return nil }

		let itemProvider: NSItemProvider = dragDropConfig.dragItemProvider?(item) ?? NSItemProvider()
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = item
		return dragItem
	}

	func willAcceptDropItem(from dragItem: UIDragItem) -> Bool
	{
		getDropItem(from: dragItem) != nil
	}

	func getDropItem(from dragItem: UIDragItem) -> Data?
	{
		guard dropEnabled else { return nil }

		let sourceItem = dragItem.localObject as? Data
		return dragDropConfig.dropItemProvider?(sourceItem, dragItem) ?? sourceItem
	}

	func getItemID<SectionID: Hashable>(for dragItem: UIDragItem, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	{
		guard let item = getDropItem(from: dragItem) else { return nil }
		return getItemID(for: item, withSectionID: sectionID)
	}

	func applyRemove(atOffsets offsets: IndexSet)
	{
		dragDropConfig.dataBinding?.wrappedValue.remove(atOffsets: offsets)
	}

	func applyInsert(items: [UIDragItem], at index: Int)
	{
		let actualItems = items.compactMap(getDropItem(from:))
		let allDataIDs = Set(dragDropConfig.dataBinding?.wrappedValue.map { $0[keyPath: dataIDKeyPath] } ?? [])
		let noDuplicates = actualItems.filter { !allDataIDs.contains($0[keyPath: dataIDKeyPath]) }
#if DEBUG
		// Notify during debug build if IDs are not unique (programmer error)
		if noDuplicates.count != actualItems.count { print("ASCOLLECTIONVIEW/ASTABLEVIEW: Attempted to insert an item with the same ID as one already in the section. This may cause unexpected behaviour.") }
#endif
		dragDropConfig.dataBinding?.wrappedValue.insert(contentsOf: noDuplicates, at: index)
	}

	func getContextMenu(for indexPath: IndexPath) -> UIContextMenuConfiguration?
	{
		guard
			let menuProvider = contextMenuProvider,
			let item = data[safe: indexPath.item]
		else { return nil }

		return menuProvider(indexPath.item, item)
	}

	func getSelfSizingSettings(context: ASSelfSizingContext) -> ASSelfSizingConfig?
	{
		selfSizingConfig?(context)
	}

	func isSelected(index: Int) -> Bool
	{
		selectedItems?.wrappedValue.contains(index) ?? false
	}

	func updateSelection(_ indices: Set<Int>)
	{
		DispatchQueue.main.async {
			self.selectedItems?.wrappedValue = Set(indices)
		}
	}

	func shouldSelect(_ indexPath: IndexPath) -> Bool
	{
		guard data.containsIndex(indexPath.item) else { return (selectedItems != nil) }
		return shouldAllowSelection?(indexPath.item) ?? (selectedItems != nil)
	}

	func shouldDeselect(_ indexPath: IndexPath) -> Bool
	{
		guard data.containsIndex(indexPath.item) else { return (selectedItems != nil) }
		return shouldAllowDeselection?(indexPath.item) ?? (selectedItems != nil)
	}
}

// MARK: SELF SIZING MODIFIERS - INTERNAL

@available(iOS 13.0, *)
internal extension ASSectionDataSource
{
	mutating func setSelfSizingConfig(config: @escaping SelfSizingConfig)
	{
		selfSizingConfig = config
	}
}
