// ASCollectionView. Created by Apptek Studios 2019

import Foundation

extension RandomAccessCollection
{
	public func containsIndex(_ index: Index) -> Bool
	{
		indices.contains(index)
	}

	subscript(safe index: Index) -> Element?
	{
		guard containsIndex(index) else { return nil }
		return self[index]
	}
}
