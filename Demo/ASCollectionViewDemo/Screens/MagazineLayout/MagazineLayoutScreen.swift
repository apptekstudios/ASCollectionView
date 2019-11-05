// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import MagazineLayout
import SwiftUI
import UIKit

struct MagazineLayoutScreen: View
{
	@State var data: [[Post]] = (0...5).map
	{
		DataSource.postsForSection($0, number: 10)
	}

	var sections: [ASCollectionViewSection<Int>]
	{
		data.enumerated().map
		{ (offset, sectionData) -> ASCollectionViewSection<Int> in
			ASCollectionViewSection(id: offset, data: sectionData, onCellEvent: onCellEvent)
			{ item, _ in
				ASRemoteImageView(item.squareThumbURL)
					.aspectRatio(1, contentMode: .fit)
					.contextMenu
				{
					Text("Test item")
					Text("Another item")
				}
			}
			.sectionSupplementary(ofKind: MagazineLayout.SupplementaryViewKind.sectionHeader)
			{
				HStack
				{
					Text("Section \(offset)")
						.padding()
					Spacer()
				}
				.background(Color.blue)
			}
		}
	}

	var body: some View
	{
		ASCollectionView(sections: self.sections)
			.layoutCustom { MagazineLayout() }
			.customDelegate(ASCollectionViewMagazineLayoutDelegate.init)
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("Magazine Layout (custom delegate)", displayMode: .inline)
	}

	func onCellEvent(_ event: CellEvent<Post>)
	{
		switch event
		{
		case let .onAppear(item):
			ASRemoteImageManager.shared.load(item.squareThumbURL)
		case let .onDisappear(item):
			ASRemoteImageManager.shared.cancelLoad(for: item.squareThumbURL)
		case let .prefetchForData(data):
			for item in data
			{
				ASRemoteImageManager.shared.load(item.squareThumbURL)
			}
		case let .cancelPrefetchForData(data):
			for item in data
			{
				ASRemoteImageManager.shared.cancelLoad(for: item.squareThumbURL)
			}
		}
	}
}

struct MagazineLayoutScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		MagazineLayoutScreen()
	}
}
