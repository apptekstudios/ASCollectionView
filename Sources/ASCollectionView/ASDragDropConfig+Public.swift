// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
public extension ASDragDropConfig
{
	init(dataBinding: Binding<[Data]>)
	{
		self.dataBinding = dataBinding
	}

	static var disabled: ASDragDropConfig<Data>
	{
		ASDragDropConfig()
	}

	func enableReordering(shouldMoveItem: ((_ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Bool)? = nil) -> Self
	{
		var this = self
		this.dragEnabled = true
		this.dropEnabled = true
		this.reorderingEnabled = true
		this.shouldMoveItem = shouldMoveItem
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
