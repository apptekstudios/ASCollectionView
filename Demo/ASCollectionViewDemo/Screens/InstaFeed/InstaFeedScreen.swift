// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

struct InstaFeedScreen: View
{
	@State var data: [[Post]] = (0...3).map { DataSource.postsForSection($0) }

	var sections: [ASCollectionViewSection<Int>]
	{
		data.enumerated().map
		{ i, sectionData in
			if i == 0 {
				return ASCollectionViewSection(id: i)
				{
					[AnyView(
						ASCollectionView(data: sectionData,
						                 onCellEvent: { event in
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
											default: break
						                 	}
						                 },
						                 layout: .init(scrollDirection: .horizontal,
						                               layout: ASCollectionViewLayoutList(itemSize: .absolute(100), sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))))
						{ item in
							StoryView(post: item)
						}
						.frame(height: 100)
						.scrollIndicatorsEnabled(false)
					)]
				}
			}
			else
			{
				return ASCollectionViewSection(id: i,
				                               data: sectionData,
				                               estimatedItemSize: CGSize(width: 0, height: 500),
				                               onCellEvent: { event in
				                               	switch event
				                               	{
				                               	case let .onAppear(item):
				                               		ASRemoteImageManager.shared.load(item.url)
				                               		ASRemoteImageManager.shared.load(item.usernamePhotoURL)
				                               	case let .onDisappear(item):
				                               		ASRemoteImageManager.shared.cancelLoad(for: item.url)
				                               		ASRemoteImageManager.shared.cancelLoad(for: item.usernamePhotoURL)
				                               	case let .prefetchForData(data):
				                               		for item in data
				                               		{
				                               			ASRemoteImageManager.shared.load(item.url)
				                               			ASRemoteImageManager.shared.load(item.usernamePhotoURL)
				                               		}
				                               	case let .cancelPrefetchForData(data):
				                               		for item in data
				                               		{
				                               			ASRemoteImageManager.shared.cancelLoad(for: item.url)
				                               			ASRemoteImageManager.shared.cancelLoad(for: item.usernamePhotoURL)
				                               		}
												default: break
				                               	}
				})
				{ item in
					PostView(post: item)
				}
			}
		}
	}

	var body: some View
	{
		ASTableView
		{
			sections
		}
		.tableViewSeparatorsEnabled(false)
		.tableViewReachedBottom
		{
			self.loadMoreContent() //REACHED BOTTOM, LOADING MORE CONTENT
		}
	}

	func loadMoreContent()
	{
		let a = data.count
		data.append(DataSource.postsForSection(a))
	}
}

struct DataSource
{
	static func postsForSection(_ sectionID: Int, number: Int = 12) -> [Post]
	{
		(0..<number).map
		{ b -> Post in
			let aspect: CGFloat = [1.0, 1.5, 0.75].randomElement() ?? 1
			return Post.randomPost(sectionID * 10_000 + b, aspectRatio: aspect)
		}
	}

	static func appsForSection(_ sectionID: Int) -> [App]
	{
		(0...17).map
		{ b -> App in
			App.randomApp(sectionID * 10_000 + b)
		}
	}
}

struct FeedView_Previews: PreviewProvider
{
	static var previews: some View
	{
		InstaFeedScreen()
	}
}
