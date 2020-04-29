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
	init(
		id: SectionID,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		container: @escaping ((Content) -> Container),
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
	{
		self.id = id
		self.data = data
		self.dataIDKeyPath = dataIDKeyPath
		self.container = container
		content = contentBuilder
	}
}

@available(iOS 13.0, *)
public extension ASSection where Container == Content
{
	init(
		id: SectionID,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
	{
		self.init(id: id, data: data, dataID: dataIDKeyPath, container: { $0 }, contentBuilder: contentBuilder)
	}
}

// MARK: IDENTIFIABLE DATA SECTION

@available(iOS 13.0, *)
public extension ASSection where DataCollection.Element: Identifiable, DataID == DataCollection.Element.ID
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
	init(
		id: SectionID,
		data: DataCollection,
		container: @escaping ((Content) -> Container),
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
	{
		self.init(id: id, data: data, dataID: \.id, container: container, contentBuilder: contentBuilder)
	}
}

@available(iOS 13.0, *)
public extension ASSection where DataCollection.Element: Identifiable, DataID == DataCollection.Element.ID, Container == Content
{
	init(
		id: SectionID,
		data: DataCollection,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
	{
		self.init(id: id, data: data, container: { $0 }, contentBuilder: contentBuilder)
	}
}

// MARK: STATIC CONTENT SECTION

@available(iOS 13.0, *)
public extension ASSection where DataCollection == [ASCollectionViewStaticContent], DataID == Int, Content == AnyView
{
	/**
	 Initializes a section with static content

	 - Parameters:
	 - id: The id for this section
	 - content: A closure returning a number of SwiftUI views to display in the collection view
	 */
	init(id: SectionID, container: @escaping ((AnyView) -> Container), @ViewArrayBuilder content: () -> ViewArrayBuilder.Wrapper)
	{
		self.id = id
		data = content().flattened().enumerated().map
		{
			ASCollectionViewStaticContent(index: $0.offset, view: $0.element)
		}
		dataIDKeyPath = \.id
		self.container = container
		self.content = { staticContent, _ in staticContent.view }
	}
}

@available(iOS 13.0, *)
public extension ASSection where DataCollection == [ASCollectionViewStaticContent], DataID == Int, Content == AnyView, Container == Content
{
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
	init<Content: View>(id: SectionID, content: () -> Content) {
		self.id = id
		data = [ASCollectionViewStaticContent(index: 0, view: AnyView(content()))]
		dataIDKeyPath = \.id
		container = { $0 }
		self.content = { staticContent, _ in staticContent.view }
	}
}
