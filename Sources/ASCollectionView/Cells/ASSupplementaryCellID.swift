// ASCollectionView. Created by Apptek Studios 2019

import Foundation

struct ASSupplementaryCellID<SectionID: Hashable>: Hashable
{
	let sectionID: SectionID
	let supplementaryKind: String
}
