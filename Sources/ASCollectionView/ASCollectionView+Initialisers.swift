// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

// MARK: Init for multi-section CVs

@available(iOS 13.0, *)
public extension ASCollectionView
{
	/**
	 Initializes a  collection view with the given sections

	 - Parameters:
	 - sections: An array of sections (ASCollectionViewSection)
	 */
	init(editMode: Bool = false, sections: [Section])
	{
		self.editMode = editMode
		self.sections = sections
	}

	/**
	 Initializes a  collection view with the given sections

	 - Parameters:
	 - sectionBuilder: A closure containing multiple sections (ASCollectionViewSection)
	 */
	init(editMode: Bool = false, @SectionArrayBuilder <SectionID> sectionBuilder: () -> [Section])
	{
		sections = sectionBuilder()
	}
}

// MARK: Init for single-section CV

@available(iOS 13.0, *)
public extension ASCollectionView where SectionID == Int
{
	/**
	 Initializes a  collection view with a single section.

	 - Parameters:
	 - section: A single section (ASCollectionViewSection)
	 */
	init(editMode: Bool = false, section: Section)
	{
		self.editMode = editMode
		sections = [section]
	}

	/**
	 Initializes a  collection view with a single section of static content
	 */
	init(editMode: Bool = false, @ViewArrayBuilder staticContent: () -> ViewArrayBuilder.Wrapper)
	{
		self.init(editMode: editMode, sections: [ASCollectionViewSection(id: 0, content: staticContent)])
	}

	/**
	 Initializes a  collection view with a single section.
	 */
	init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View>(
		editMode: Bool = false,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int
	{
		self.editMode = editMode
		let section = ASCollectionViewSection(
			id: 0,
			data: data,
			dataID: dataIDKeyPath,
			contentBuilder: contentBuilder)
		sections = [section]
	}

	/**
	 Initializes a  collection view with a single section with identifiable data
	 */
	init<DataCollection: RandomAccessCollection, Content: View>(
		editMode: Bool = false,
		data: DataCollection,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int, DataCollection.Element: Identifiable
	{
		self.init(editMode: editMode, data: data, dataID: \.id, contentBuilder: contentBuilder)
	}
}
