// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public struct ASWrappedSection<SectionID: Hashable>
{
	var id: SectionID
	var section: ASSectionDataSourceProtocol

	public init<DataCollection: RandomAccessCollection, DataID, Content: View, Container: View>(_ section: ASSection<SectionID, DataCollection, DataID, Content, Container>) {
		id = section.id
		self.section = section
	}
}
