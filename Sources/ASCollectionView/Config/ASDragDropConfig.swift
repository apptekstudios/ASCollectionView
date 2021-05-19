// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
public struct ASDragDropConfig<Data>
{
	// MARK: Automatic handling

	var dataBinding: Binding<[Data]>?

	// MARK: Manual handling

	var onDeleteOrRemoveItems: ((_ indexSet: IndexSet) -> Bool)?
	var onInsertItems: ((_ index: Int, _ items: [Data]) -> Bool)?
	var onMoveItem: ((_ from: Int, _ to: Int) -> Bool)?

	// MARK: Shared

	var dragEnabled: Bool = false
	var dropEnabled: Bool = false
	var reorderingEnabled: Bool = false

	/// Called to check whether an item can be dragged
	var canDragItem: ((_ indexPath: IndexPath) -> Bool)?

	/// Called to check whether an item can be moved to the specified indexPath
	var canMoveItem: ((_ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Bool)?

	/// Called to check whether an item can be dropped
	var canDropItem: ((_ indexPath: IndexPath) -> Bool)?

	var dragItemProvider: ((_ item: Data) -> NSItemProvider?)?

	var dropItemProvider: ((_ sourceItem: Data?, _ dragItem: UIDragItem) -> Data?)?

	init()
	{
		// Used to provide `disabled` mode
	}
}
