//
//  GroupLarge.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 26/10/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import SwiftUI

struct GroupLarge: View {
	var model: GroupModel
	
    var body: some View {
		VStack(alignment: .leading) {
			HStack(alignment: .center) {
				Image(systemName: model.icon)
					.foregroundColor(.white)
					.padding(10)
					.background(
						Circle().fill(model.color)
				)
				Spacer()
				model.contentCount.map {
					Text("\($0)")
						.font(.title)
						.bold()
				}
			}
			Text(model.title)
				.bold()
				.multilineTextAlignment(.leading)
				.foregroundColor(Color(.secondaryLabel))
		}
		.padding()
		.background(Color(.secondarySystemGroupedBackground))
	.clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct GroupLarge_Previews: PreviewProvider {
    static var previews: some View {
		ZStack {
			Color(.secondarySystemBackground)
			GroupLarge(model: .demo)
		}
    }
}
