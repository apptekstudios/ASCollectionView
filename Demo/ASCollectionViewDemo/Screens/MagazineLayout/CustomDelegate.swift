//
//  CustomDelegate.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 23/10/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import UIKit
import ASCollectionView
import MagazineLayout

class ASCollectionViewMagazineLayoutDelegate: ASCollectionViewDelegate, UICollectionViewDelegateMagazineLayout {
    override func collectionView(cellShouldSelfSizeVerticallyForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(cellShouldSelfSizeHorizontallyForItemAt indexPath: IndexPath) -> Bool {
        return false
    }
	
	override var collectionViewContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
		.always
	}
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode {
        let rowIsThree = (indexPath.item % 5) < 3
        let widthMode = rowIsThree ? MagazineLayoutItemWidthMode.thirdWidth : MagazineLayoutItemWidthMode.halfWidth
        let heightMode = MagazineLayoutItemHeightMode.dynamic
        return MagazineLayoutItemSizeMode(widthMode: widthMode, heightMode: heightMode)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForHeaderInSectionAtIndex index: Int) -> MagazineLayoutHeaderVisibilityMode {
        return .visible(heightMode: .dynamic, pinToVisibleBounds: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForFooterInSectionAtIndex index: Int) -> MagazineLayoutFooterVisibilityMode {
        return .visible(heightMode: .dynamic, pinToVisibleBounds: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForBackgroundInSectionAtIndex index: Int) -> MagazineLayoutBackgroundVisibilityMode {
        return .hidden
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalSpacingForItemsInSectionAtIndex index: Int) -> CGFloat {
        return  12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat {
        return  12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 24, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
    }
    
}
