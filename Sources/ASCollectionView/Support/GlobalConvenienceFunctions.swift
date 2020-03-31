// ASCollectionView. Created by Apptek Studios 2019

import Foundation

func assignIfChanged<Object: AnyObject, T: Equatable>(_ object: Object, _ keyPath: ReferenceWritableKeyPath<Object, T>, newValue: T) {
	guard newValue != object[keyPath: keyPath] else { return }
	object[keyPath: keyPath] = newValue
}
