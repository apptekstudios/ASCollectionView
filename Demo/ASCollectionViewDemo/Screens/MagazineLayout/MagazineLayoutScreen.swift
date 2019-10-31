// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit
import MagazineLayout

struct MagazineLayoutScreen: View
{
    @State var data: [[Post]] = (0...5).map {
        DataSource.postsForSection($0, number: 10)
        }

	var sections: [ASCollectionViewSection<Int>]
	{
		data.enumerated().map
		{ (offset, sectionData) -> ASCollectionViewSection<Int> in
			ASCollectionViewSection(id: offset, data: sectionData, onCellEvent: { event in
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
			})
			{ item in
				ASRemoteImageView(item.squareThumbURL)
					.aspectRatio(1, contentMode: .fit)
					.contextMenu {
						Text("Test item")
						Text("Another item")
				}
			}
            .sectionSupplementary(ofKind: MagazineLayout.SupplementaryViewKind.sectionHeader) {
                HStack {
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
		ASCollectionView(layout: .init(customLayout: { MagazineLayout() }),
						 sections: self.sections)
			.customDelegate(ASCollectionViewMagazineLayoutDelegate.init)
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("Magazine Layout (custom delegate)", displayMode: .inline)
	}
}

struct MagazineLayoutScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		MagazineLayoutScreen()
	}
}
