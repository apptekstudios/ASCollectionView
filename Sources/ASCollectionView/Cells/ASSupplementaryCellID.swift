//
//  File.swift
//  
//
//  Created by Toby Brennan on 19/4/20.
//

import Foundation

struct ASSupplementaryCellID<SectionID: Hashable>: Hashable {
	let sectionID: SectionID
	let supplementaryKind: String
}
