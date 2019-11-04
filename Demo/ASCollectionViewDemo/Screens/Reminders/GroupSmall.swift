// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

struct GroupSmall: View
{
	var model: GroupModel

	var body: some View
	{
		HStack(alignment: .center)
		{
			Image(systemName: model.icon)
				.font(.system(size: 16, weight: .regular))
				.padding(14)
				.foregroundColor(.white)
				.background(
					Circle().fill(model.color)
				)

			Text(model.title)
				.multilineTextAlignment(.leading)
				.foregroundColor(Color(.label))

			Spacer()
			model.contentCount.map
			{
				Text("\($0)")
			}
		}
		.padding(10)
	}
}

struct GroupSmall_Previews: PreviewProvider
{
	static var previews: some View
	{
		GroupSmall(model: .demo)
	}
}
