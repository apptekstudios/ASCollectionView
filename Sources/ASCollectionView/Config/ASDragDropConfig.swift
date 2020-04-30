// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
public struct ASDragDropConfig<Data>
{
	var dataBinding: Binding<[Data]>?

	var dragEnabled: Bool = false
	var dropEnabled: Bool = false
	var reorderingEnabled: Bool = false

	var dragItemProvider: ((_ item: Data) -> NSItemProvider?)?
	var shouldMoveItem: ((_ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Bool)?

	/// An optional closure that you can use to decide what to do with a dropped item.
	/// Return nil if you want to ignore the drop.
	/// Return an item (of the same type as your section data) if you want to insert a row.
	/// `sourceItem`: If the drop originated from a cell with the same data source, this will provide the original item that has been dragged
	/// `dragItem`: This is the further information provided by UIKit. For example, if a drag came from another app, you could deal with that using this.
	var dropItemProvider: ((_ sourceItem: Data?, _ dragItem: UIDragItem) -> Data?)?
}
