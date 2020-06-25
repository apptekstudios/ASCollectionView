// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public extension ASTableView
{
	/**
	 Initializes a  table view with the given sections

	 - Parameters:
	 - sections: An array of sections (ASTableViewSection)
	 */
	@inlinable init(style: UITableView.Style = .plain, editMode: Bool = false, sections: [Section])
	{
		self.style = style
        self.editMode = editMode
		self.sections = sections
	}

	@inlinable init(style: UITableView.Style = .plain, editMode: Bool = false, @SectionArrayBuilder <SectionID> sectionBuilder: () -> [Section])
	{
		self.style = style
        self.editMode = editMode
		sections = sectionBuilder()
	}
}

@available(iOS 13.0, *)
public extension ASTableView where SectionID == Int
{
	/**
	 Initializes a  table view with a single section.

	 - Parameters:
	 - section: A single section (ASTableViewSection)
	 */
    init(style: UITableView.Style = .plain, editMode: Bool = false, section: Section)
	{
		self.style = style
        self.editMode = editMode
		sections = [section]
	}

	/**
	 Initializes a  table view with a single section.
	 */
	init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View>(
		style: UITableView.Style = .plain,
        editMode: Bool = false,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int
	{
		self.style = style
        self.editMode = editMode
		let section = ASSection(
			id: 0,
			data: data,
			dataID: dataIDKeyPath,
			contentBuilder: contentBuilder)
		sections = [section]
	}

	/**
	 Initializes a  table view with a single section of identifiable data
	 */
	init<DataCollection: RandomAccessCollection, Content: View>(
		style: UITableView.Style = .plain,
        editMode: Bool = false,
		data: DataCollection,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, ASCellContext) -> Content))
		where DataCollection.Index == Int, DataCollection.Element: Identifiable
	{
        self.init(style: style, editMode: editMode, data: data, dataID: \.id, contentBuilder: contentBuilder)
	}

	/**
	 Initializes a  table view with a single section of static content
	 */
	static func `static`(editMode: Bool = false, @ViewArrayBuilder staticContent: () -> ViewArrayBuilder.Wrapper) -> ASTableView
	{
		ASTableView(
			style: .plain,
            editMode: editMode,
			sections: [ASTableViewSection(id: 0, content: staticContent)])
	}
}
