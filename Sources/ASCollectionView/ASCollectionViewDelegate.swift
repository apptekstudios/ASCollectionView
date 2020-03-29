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

	public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
	}

	public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
	}

	public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
	}

	public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath)
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		coordinator?.collectionView(collectionView, didSelectItemAt: indexPath)
	}

	public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
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
	public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
	{
		guard let dragItem = coordinator?.dragItem(for: indexPath) else { return [] }
		return [dragItem]
	}

	public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal
	{
		guard session.localDragSession != nil else
		{
			return UICollectionViewDropProposal(operation: .forbidden)
		}
		if collectionView.hasActiveDrag
		{
			if let destination = destinationIndexPath
			{
				guard coordinator?.canDrop(at: destination) ?? false else
				{
					return UICollectionViewDropProposal(operation: .cancel)
				}
			}
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
		else
		{
			return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
		}
	}

	public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator)
	{
		var proposedDestinationIndexPath: IndexPath? = coordinator.destinationIndexPath

		if proposedDestinationIndexPath == nil, collectionView.numberOfSections != 0
		{
			// Get last index path of collection view.
			let section = collectionView.numberOfSections - 1
			let row = collectionView.numberOfItems(inSection: section)
			proposedDestinationIndexPath = IndexPath(row: row, section: section)
		}

		guard let destinationIndexPath = proposedDestinationIndexPath else { return }

		switch coordinator.proposal.operation
		{
		case .move:
			coordinator.items.forEach
			{ item in
				if let sourceIndex = item.sourceIndexPath
				{
					self.coordinator?.removeItem(from: sourceIndex)
				}
			}

			self.coordinator?.insertItems(coordinator.items.map { $0.dragItem }, at: destinationIndexPath)
			/* self.coordinator?.afterNextUpdate = {
			 coordinator.items.forEach { (item) in
			 coordinator.drop(item.dragItem, toItemAt: destinationIndexPath) // This assumption is flawed if dropping multiple items
			 }
			 } */

		case .copy:
			self.coordinator?.insertItems(coordinator.items.map { $0.dragItem }, at: destinationIndexPath)

		default:
			return
		}
	}

	public func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		self.coordinator?.scrollViewDidScroll(scrollView)
	}
}

@available(iOS 13.0, *)
extension ASCollectionViewDelegate
{
	public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
	{
		coordinator?.collectionView(collectionView, contextMenuConfigurationForItemAt: indexPath, point: point)
	}
}
