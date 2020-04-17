// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: DYNAMIC CONTENT SECTION

@available(iOS 13.0, *)
public extension ASSection
{
	/**
	 Initializes a  section with data

	 - Parameters:
	 - id: The id for this section
	 - data: The data to display in the section. This initialiser expects data that conforms to 'Identifiable'
	 - dataID: The keypath to a hashable identifier of each data item
	 - onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
	 - onDragDropEvent: Define this closure to enable drag/drop and respond to events (default is nil: drag/drop disabled)
	 - contentBuilder: A closure returning a SwiftUI view for the given data item
	 */
	init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View, Container: View>(
		id: SectionID,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		container: @escaping ((Content) -> Container),
		selectedItems: Binding<Set<Int>>? = nil,
		shouldAllowSelection: ((_ index: Int) -> Bool)? = nil,
		shouldAllowDeselection: ((_ index: Int) -> Bool)? = nil,
		onCellEvent: OnCellEvent<DataCollection.Element>? = nil,
		dragDropConfig: ASDragDropConfig<DataCollection.Element> = .disabled,
		shouldAllowSwipeToDelete: ShouldAllowSwipeToDelete? = nil,
		onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>? = nil,
		contextMenuProvider: ContextMenuProvider<DataCollection.Element>? = nil,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int
	{
		self.id = id
		dataSource = ASSectionDataSource<DataCollection, DataID, Content, Container>(
			data: data,
			dataIDKeyPath: dataIDKeyPath,
			container: container,
			content: contentBuilder,
			selectedItems: selectedItems,
			shouldAllowSelection: shouldAllowSelection,
			shouldAllowDeselection: shouldAllowDeselection,
			onCellEvent: onCellEvent,
			dragDropConfig: dragDropConfig,
			shouldAllowSwipeToDelete: shouldAllowSwipeToDelete,
			onSwipeToDelete: onSwipeToDelete,
			contextMenuProvider: contextMenuProvider)
	}

	init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View>(
		id: SectionID,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		selectedItems: Binding<Set<Int>>? = nil,
		shouldAllowSelection: ((_ index: Int) -> Bool)? = nil,
		shouldAllowDeselection: ((_ index: Int) -> Bool)? = nil,
		onCellEvent: OnCellEvent<DataCollection.Element>? = nil,
		dragDropConfig: ASDragDropConfig<DataCollection.Element> = .disabled,
		shouldAllowSwipeToDelete: ShouldAllowSwipeToDelete? = nil,
		onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>? = nil,
		contextMenuProvider: ContextMenuProvider<DataCollection.Element>? = nil,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int
	{
		self.init(id: id, data: data, dataID: dataIDKeyPath, container: { $0 }, selectedItems: selectedItems, shouldAllowSelection: shouldAllowSelection, shouldAllowDeselection: shouldAllowDeselection, onCellEvent: onCellEvent, dragDropConfig: dragDropConfig, shouldAllowSwipeToDelete: shouldAllowSwipeToDelete, onSwipeToDelete: onSwipeToDelete, contextMenuProvider: contextMenuProvider, contentBuilder: contentBuilder)
	}
}

// MARK: IDENTIFIABLE DATA SECTION

@available(iOS 13.0, *)
public extension ASCollectionViewSection
{
	/**
	 Initializes a  section with identifiable data
	 - Parameters:
	 - id: The id for this section
	 - data: The data to display in the section. This initialiser expects data that conforms to 'Identifiable'
	 - onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
	 - onDragDropEvent: Define this closure to enable drag/drop and respond to events (default is nil: drag/drop disabled)
	 - contentBuilder: A closure returning a SwiftUI view for the given data item
	 */
	init<Content: View, Container: View, DataCollection: RandomAccessCollection>(
		id: SectionID,
		data: DataCollection,
		container: @escaping ((Content) -> Container),
		selectedItems: Binding<Set<Int>>? = nil,
		shouldAllowSelection: ((_ index: Int) -> Bool)? = nil,
		shouldAllowDeselection: ((_ index: Int) -> Bool)? = nil,
		onCellEvent: OnCellEvent<DataCollection.Element>? = nil,
		dragDropConfig: ASDragDropConfig<DataCollection.Element> = .disabled,
		shouldAllowSwipeToDelete: ShouldAllowSwipeToDelete? = nil,
		onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>? = nil,
		contextMenuProvider: ContextMenuProvider<DataCollection.Element>? = nil,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int, DataCollection.Element: Identifiable
	{
		self.init(id: id, data: data, dataID: \.id, container: container, selectedItems: selectedItems, shouldAllowSelection: shouldAllowSelection, shouldAllowDeselection: shouldAllowDeselection, onCellEvent: onCellEvent, dragDropConfig: dragDropConfig, shouldAllowSwipeToDelete: shouldAllowSwipeToDelete, onSwipeToDelete: onSwipeToDelete, contextMenuProvider: contextMenuProvider, contentBuilder: contentBuilder)
	}

	init<Content: View, DataCollection: RandomAccessCollection>(
		id: SectionID,
		data: DataCollection,
		selectedItems: Binding<Set<Int>>? = nil,
		shouldAllowSelection: ((_ index: Int) -> Bool)? = nil,
		shouldAllowDeselection: ((_ index: Int) -> Bool)? = nil,
		onCellEvent: OnCellEvent<DataCollection.Element>? = nil,
		dragDropConfig: ASDragDropConfig<DataCollection.Element> = .disabled,
		shouldAllowSwipeToDelete: ShouldAllowSwipeToDelete? = nil,
		onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>? = nil,
		contextMenuProvider: ContextMenuProvider<DataCollection.Element>? = nil,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int, DataCollection.Element: Identifiable
	{
		self.init(id: id, data: data, container: { $0 }, selectedItems: selectedItems, shouldAllowSelection: shouldAllowSelection, shouldAllowDeselection: shouldAllowDeselection, onCellEvent: onCellEvent, dragDropConfig: dragDropConfig, shouldAllowSwipeToDelete: shouldAllowSwipeToDelete, onSwipeToDelete: onSwipeToDelete, contextMenuProvider: contextMenuProvider, contentBuilder: contentBuilder)
	}
}

// MARK: STATIC CONTENT SECTION

@available(iOS 13.0, *)
public extension ASCollectionViewSection
{
	/**
	 Initializes a section with static content

	 - Parameters:
	 - id: The id for this section
	 - content: A closure returning a number of SwiftUI views to display in the collection view
	 */
	init<Container: View>(id: SectionID, container: @escaping ((AnyView) -> Container), @ViewArrayBuilder content: () -> ViewArrayBuilder.Wrapper)
	{
		self.id = id
		dataSource = ASSectionDataSource<[ASCollectionViewStaticContent], ASCollectionViewStaticContent.ID, AnyView, Container>(
			data: content().flattened().enumerated().map
			{
				ASCollectionViewStaticContent(index: $0.offset, view: $0.element)
			},
			dataIDKeyPath: \.id,
			container: container,
			content: { staticContent, _ in staticContent.view },
			dragDropConfig: .disabled)
	}

	init(id: SectionID, @ViewArrayBuilder content: () -> ViewArrayBuilder.Wrapper)
	{
		self.init(id: id, container: { $0 }, content: content)
	}

	/**
	 Initializes a section with a single view

	 - Parameters:
	 - id: The id for this section
	 - content: A single SwiftUI views to display in the collection view
	 */
	init<Content: View, Container: View>(id: SectionID, container: @escaping ((AnyView) -> Container), content: () -> Content)
	{
		self.id = id
		dataSource = ASSectionDataSource<[ASCollectionViewStaticContent], ASCollectionViewStaticContent.ID, AnyView, Container>(
			data: [ASCollectionViewStaticContent(index: 0, view: AnyView(content()))],
			dataIDKeyPath: \.id,
			container: container,
			content: { staticContent, _ in staticContent.view },
			dragDropConfig: .disabled)
	}

	init<Content: View>(id: SectionID, content: () -> Content) {
		self.init(id: id, container: { $0 }, content: content)
	}
}
