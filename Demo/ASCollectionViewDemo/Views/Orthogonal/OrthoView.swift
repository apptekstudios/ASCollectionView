// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI

struct OrthoView: View
{
	@State var data: [(sectionTitle: String, apps: [App])] = (0...20).map
	{
		(Lorem.title, DataSource.appsForSection($0))
	}

	var layout: ASCollectionViewLayout<Int>
	{
		ASCollectionViewLayout<Int>(scrollDirection: .vertical, interSectionSpacing: 20)
		{ sectionID -> ASCollectionViewLayoutSection in
			let insets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
			switch sectionID
			{
			case 0:
				var layout = ASCollectionViewLayoutOrthogonalGrid()
				layout.gridSize = 1
				layout.itemInsets = insets
				layout.itemDimension = .fractionalWidth(0.9)
				layout.orthogonalScrollingBehavior = .groupPagingCentered
				layout.sectionDimension = .absolute(300)
				return layout
			case 1:
				var layout = ASCollectionViewLayoutOrthogonalGrid()
				layout.gridSize = 2
				layout.itemInsets = insets
				layout.orthogonalScrollingBehavior = .groupPagingCentered
				layout.sectionDimension = .absolute(200)
				return layout
			default:
				var layout = ASCollectionViewLayoutOrthogonalGrid()
				layout.gridSize = 3
				layout.itemInsets = insets
				layout.orthogonalScrollingBehavior = .groupPagingCentered
				layout.sectionDimension = .absolute(250)
				return layout
			}
		}
	}

	func header(withTitle title: String) -> some View
	{
		HStack
		{
			Text(title)
				.font(.title)
			Spacer()
			Button(action: {
				//
			})
			{
				Text("See all")
			}
		}.padding([.top, .bottom])
	}

	var sections: [ASCollectionViewSection<Int>]
	{
		data.enumerated().map
		{ (sectionID, sectionData) -> ASCollectionViewSection<Int> in
			ASCollectionViewSection(id: sectionID,
			                        header: header(withTitle: sectionData.sectionTitle),
			                        data: sectionData.apps,
			                        onCellEvent: { event in
			                        	switch event
			                        	{
			                        	case let .onAppear(item):
			                        		switch sectionID
			                        		{
			                        		case 0:
			                        			ASRemoteImageManager.shared.load(item.featureImageURL)
			                        		default:
			                        			ASRemoteImageManager.shared.load(item.squareThumbURL)
			                        		}
			                        	case let .onDisappear(item):
			                        		switch sectionID
			                        		{
			                        		case 0:
			                        			ASRemoteImageManager.shared.cancelLoad(for: item.featureImageURL)
			                        		default:
			                        			ASRemoteImageManager.shared.cancelLoad(for: item.squareThumbURL)
			                        		}
			                        	case let .prefetchForData(data):
			                        		for item in data
			                        		{
			                        			switch sectionID
			                        			{
			                        			case 0:
			                        				ASRemoteImageManager.shared.load(item.featureImageURL)
			                        			default:
			                        				ASRemoteImageManager.shared.load(item.squareThumbURL)
			                        			}
			                        		}
			                        	case let .cancelPrefetchForData(data):
			                        		for item in data
			                        		{
			                        			switch sectionID
			                        			{
			                        			case 0:
			                        				ASRemoteImageManager.shared.cancelLoad(for: item.featureImageURL)
			                        			default:
			                        				ASRemoteImageManager.shared.cancelLoad(for: item.squareThumbURL)
			                        			}
			                        		}
			                        	}
			})
			{ item in
				if sectionID == 0 {
					AppViewFeature(app: item)
				}
				else if sectionID == 1 {
					AppViewLarge(app: item)
				}
				else
				{
					AppViewCompact(app: item)
				}
			}
		}
	}

	var body: some View
	{
		NavigationView
		{
			ASCollectionView(layout: self.layout,
			                 sections: self.sections)
				.navigationBarTitle("Apps", displayMode: .inline)
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
}

struct OrthoView_Previews: PreviewProvider
{
	static var previews: some View
	{
		OrthoView()
	}
}
