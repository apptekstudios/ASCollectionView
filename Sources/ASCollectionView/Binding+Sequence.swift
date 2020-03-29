// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public extension Binding where Value == [Int: Set<Int>]
{
	subscript(index: Int) -> Binding<Set<Int>>
	{
		Binding<Set<Int>>(get: {
			self.wrappedValue[index] ?? []
		}, set: {
			self.wrappedValue[index] = $0
		})
	}
}
