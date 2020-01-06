// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

struct GroupModel: Identifiable
{
	var icon: String
	var title: String
	var contentCount: Int? = Int.random(in: 0 ... 20)
	var color: Color = [Color.red, Color.orange, Color.blue, Color.purple].randomElement()!

	static var demo = GroupModel(icon: "paperplane", title: "Test category", contentCount: 19)

	var id: String { title }
}
