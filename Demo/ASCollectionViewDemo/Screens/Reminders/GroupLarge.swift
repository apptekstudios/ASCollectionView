// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

struct GroupLarge: View
{
	var model: GroupModel

	var body: some View
	{
		VStack(alignment: .leading)
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
				Spacer()
				model.contentCount.map
				{
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
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
}

struct GroupLarge_Previews: PreviewProvider
{
	static var previews: some View
	{
		ZStack
		{
			Color(.secondarySystemBackground)
			GroupLarge(model: .demo)
		}
	}
}
