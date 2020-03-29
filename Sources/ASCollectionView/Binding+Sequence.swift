//
//  File.swift
//  
//
//  Created by Toby Brennan on 27/3/20.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public extension Binding where Value == Dictionary<Int, Set<Int>> {
	subscript(index: Int) -> Binding<Set<Int>>
	{
		Binding<Set<Int>>(get: {
			self.wrappedValue[index] ?? []
		}, set: {
			self.wrappedValue[index] = $0
		})
	}
}
