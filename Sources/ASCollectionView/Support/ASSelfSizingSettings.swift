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
	public init(selfSizeHorizontally: Bool? = nil, selfSizeVertically: Bool? = nil, canExceedCollectionWidth: Bool = true, canExceedCollectionHeight: Bool = true)
	{
		self.selfSizeHorizontally = selfSizeHorizontally
		self.selfSizeVertically = selfSizeVertically
		self.canExceedCollectionWidth = canExceedCollectionWidth
		self.canExceedCollectionHeight = canExceedCollectionHeight
	}

	var selfSizeHorizontally: Bool?
	var selfSizeVertically: Bool?
	var canExceedCollectionWidth: Bool
	var canExceedCollectionHeight: Bool
}
