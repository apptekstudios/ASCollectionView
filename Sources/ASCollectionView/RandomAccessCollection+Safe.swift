//
//  File.swift
//  
//
//  Created by Toby Brennan on 4/1/20.
//

import Foundation

extension RandomAccessCollection {
	func containsIndex(_ index: Index) -> Bool {
		index >= startIndex && index < endIndex
	}
	subscript(safe index: Index) -> Element? {
		get {
			guard containsIndex(index) else { return nil }
			return self[index]
		}
	}
}
