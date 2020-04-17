// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import UIKit

@available(iOS 13.0, *)
public enum CellEvent<Data>
{
	/// Respond by starting necessary prefetch operations for this data to be displayed soon (eg. download images)
	case prefetchForData(data: [Data])

	/// Called when its no longer necessary to prefetch this data
	case cancelPrefetchForData(data: [Data])

	/// Called when an item is appearing on the screen
	case onAppear(item: Data)

	/// Called when an item is disappearing from the screen
	case onDisappear(item: Data)
}

@available(iOS 13.0, *)
public typealias OnCellEvent<Data> = ((_ event: CellEvent<Data>) -> Void)

@available(iOS 13.0, *)
public typealias ShouldAllowSwipeToDelete = ((_ index: Int) -> Bool)

@available(iOS 13.0, *)
public typealias OnSwipeToDelete<Data> = ((_ index: Int, _ item: Data, _ completionHandler: (Bool) -> Void) -> Void)

@available(iOS 13.0, *)
public typealias ContextMenuProvider<Data> = ((_ index: Int, _ item: Data) -> UIContextMenuConfiguration?)

@available(iOS 13.0, *)
public typealias SelfSizingConfig = ((_ context: ASSelfSizingContext) -> ASSelfSizingConfig?)
