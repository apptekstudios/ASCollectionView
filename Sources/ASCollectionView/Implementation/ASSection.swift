// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public struct ASCollectionViewStaticContent: Identifiable
{
	public var index: Int
	var view: AnyView

	public var id: Int { index }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
public struct ASSectionWrapped<SectionID: Hashable>
{
	var id: SectionID
	var section: ASSectionDataSourceProtocol

	public init<DataCollection: RandomAccessCollection, DataID, Content: View, Container: View>(_ section: ASSection<SectionID, DataCollection, DataID, Content, Container>) {
		id = section.id
		self.section = section
	}
}
