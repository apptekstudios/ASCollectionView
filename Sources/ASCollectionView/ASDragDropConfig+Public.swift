// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
public extension ASDragDropConfig
{
	/// This provides automatic support for drag/drop/reorder of items in the section
	/// It automatically applies changes using the data binding
	/// Use the modifiers to add extra checks (eg .canDragItem, .canMoveItem, .dragItemProvider, .dropItemProvider)
	init(dataBinding: Binding<[Data]>, dragEnabled: Bool = true, dropEnabled: Bool = true, reorderingEnabled: Bool = true)
	{
		self.dataBinding = dataBinding
		self.dragEnabled = dragEnabled
		self.dropEnabled = dropEnabled
		self.reorderingEnabled = reorderingEnabled
	}

	/// This allows you to manually implement drag/drop/reordering support
	/// In the onDelete/onInsert/onMove closures return true if you apply the suggested delete/insert/move, or false if it shouldn't be applied... so that ASCollectionView can correctly animate.
	/// Use the modifiers to add extra checks (eg .canDragItem, .canMoveItem, .dragItemProvider, .dropItemProvider)
	init(dragEnabled: Bool = true, dropEnabled: Bool = true, reorderingEnabled: Bool = true, onDeleteOrRemoveItems: ((_ indexSet: IndexSet) -> Bool)? = nil, onInsertItems: ((_ index: Int, _ items: [Data]) -> Bool)? = nil, onMoveItem: ((Int, Int) -> Bool)? = nil)
	{
		dataBinding = nil
		self.onDeleteOrRemoveItems = onDeleteOrRemoveItems
		self.onInsertItems = onInsertItems
		self.onMoveItem = onMoveItem
		self.dragEnabled = dragEnabled
		self.dropEnabled = dropEnabled
		self.reorderingEnabled = reorderingEnabled
	}

	static var disabled: ASDragDropConfig<Data>
	{
		ASDragDropConfig()
	}

	func canDragItem(_ closure: @escaping ((IndexPath) -> Bool)) -> Self
	{
		var this = self
		this.canDragItem = closure
		return this
	}

	func canMoveItem(_ closure: @escaping ((IndexPath, IndexPath) -> Bool)) -> Self
	{
		var this = self
		this.canMoveItem = closure
		return this
	}

	func dropItemProvider(_ provider: @escaping ((Data?, UIDragItem) -> Data?)) -> Self
	{
		var this = self
		this.dropEnabled = true
		this.dropItemProvider = provider
		return this
	}

	func dragItemProvider(_ provider: @escaping ((_ item: Data) -> NSItemProvider?)) -> Self
	{
		var this = self
		this.dragEnabled = true
		this.dragItemProvider = provider
		return this
	}
}
