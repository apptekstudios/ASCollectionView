// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import MagazineLayout
import UIKit

class ASCollectionViewMagazineLayoutDelegate: ASCollectionViewDelegate, UICollectionViewDelegateMagazineLayout
{
	override func collectionView(cellShouldSelfSizeVerticallyForItemAt indexPath: IndexPath) -> Bool
	{
		true
	}

	override func collectionView(cellShouldSelfSizeHorizontallyForItemAt indexPath: IndexPath) -> Bool
	{
		false
	}

	override var collectionViewContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior
	{
		.always
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode
	{
		let rowIsThree = (indexPath.item % 5) < 3
		let widthMode = rowIsThree ? MagazineLayoutItemWidthMode.thirdWidth : MagazineLayoutItemWidthMode.halfWidth
		let heightMode = MagazineLayoutItemHeightMode.dynamic
		return MagazineLayoutItemSizeMode(widthMode: widthMode, heightMode: heightMode)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForHeaderInSectionAtIndex index: Int) -> MagazineLayoutHeaderVisibilityMode
	{
		.visible(heightMode: .dynamic, pinToVisibleBounds: true)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForFooterInSectionAtIndex index: Int) -> MagazineLayoutFooterVisibilityMode
	{
		.visible(heightMode: .dynamic, pinToVisibleBounds: false)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForBackgroundInSectionAtIndex index: Int) -> MagazineLayoutBackgroundVisibilityMode
	{
		.hidden
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalSpacingForItemsInSectionAtIndex index: Int) -> CGFloat
	{
		12
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat
	{
		12
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets
	{
		UIEdgeInsets(top: 0, left: 8, bottom: 24, right: 8)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets
	{
		UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
	}
}
