// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

/// ASCollectionViewDelegate: Subclass this to create a custom delegate (eg. for supporting UICollectionViewLayouts that default to using the collectionView delegate)
@available(iOS 13.0, *)
open class ASCollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
	weak var coordinator: ASCollectionViewCoordinator?

	public func getDataForItem(at indexPath: IndexPath) -> Any?
	{
		coordinator?.typeErasedDataForItem(at: indexPath)
	}

	public func getDataForItem<T>(at indexPath: IndexPath) -> T?
	{
		coordinator?.typeErasedDataForItem(at: indexPath) as? T
	}

	open func collectionViewSelfSizingSettings(forContext: ASSelfSizingContext) -> ASSelfSizingConfig?
	{
		nil
	}

	open var collectionViewContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior
	{
		.scrollableAxes
	}

	open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
	}

	open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
	}

	open func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
	}

	open func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath)
	}

	open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didSelectItemAt: indexPath)
	}

	open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didDeselectItemAt: indexPath)
	}

	/*
	 //REPLACED WITH CUSTOM PREFETCH SOLUTION AS PREFETCH API WAS NOT WORKING FOR COMPOSITIONAL LAYOUT
	 public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])
	 public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath])
	 */
}

@available(iOS 13.0, *)
extension ASCollectionViewDelegate: UICollectionViewDragDelegate, UICollectionViewDropDelegate
{
	open func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool
	{
		true
	}

	open func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
	{
		coordinator?.collectionView(collectionView, itemsForBeginning: session, at: indexPath) ?? []
	}

	open func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal
	{
		coordinator?.collectionView(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath) ?? UICollectionViewDropProposal(operation: .cancel)
	}

	open func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator)
	{
		self.coordinator?.collectionView(collectionView, performDropWith: coordinator)
	}

	open func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		coordinator?.scrollViewDidScroll(scrollView)
	}
}

@available(iOS 13.0, *)
extension ASCollectionViewDelegate
{
	open func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
	{
		coordinator?.collectionView(collectionView, contextMenuConfigurationForItemAt: indexPath, point: point)
	}
}
