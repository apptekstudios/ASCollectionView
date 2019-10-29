//
//  GroupModel.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 26/10/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import SwiftUI

struct GroupModel: Identifiable {
	var icon: String
	var title: String
	var contentCount: Int? = Int.random(in: 0...20)
	var color: Color = [Color.red, Color.orange, Color.blue, Color.purple].randomElement()!
	
	static var demo = GroupModel(icon: "paperplane", title: "Test category", contentCount: 19)
	
	var id: String { title }
}
