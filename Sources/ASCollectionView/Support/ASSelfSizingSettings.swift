// ASCollectionView. Created by Apptek Studios 2019

import Foundation

public struct ASSelfSizingContext
{
	public enum CellType
	{
		case content
		case supplementary(String)
	}

	public let cellType: CellType
	public let indexPath: IndexPath
}

public struct ASSelfSizingConfig
{
	public init(selfSizeHorizontally: Bool, selfSizeVertically: Bool)
	{
		self.selfSizeHorizontally = selfSizeHorizontally
		self.selfSizeVertically = selfSizeVertically
	}

	let selfSizeHorizontally: Bool
	let selfSizeVertically: Bool
}
