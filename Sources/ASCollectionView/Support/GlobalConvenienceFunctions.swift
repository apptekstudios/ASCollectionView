// ASCollectionView. Created by Apptek Studios 2019

import Foundation

@discardableResult
func assignIfChanged<Object: AnyObject, T: Equatable>(_ object: Object, _ keyPath: ReferenceWritableKeyPath<Object, T>, newValue: T) -> Bool
{
	guard newValue != object[keyPath: keyPath] else { return false }
	object[keyPath: keyPath] = newValue
	return true
}
