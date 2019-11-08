// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

struct InstaFeedScreen: View
{
	@State var data: [[Post]] = (0...3).map { DataSource.postsForSection($0) }

	var sections: [ASTableViewSection<Int>]
	{
		data.enumerated().map
		{ i, sectionData in
			if i == 0 {
				return ASTableViewSection(id: i)
				{
					ASCollectionView(
						section:
						ASCollectionViewSection(
							id: 0,
							data: sectionData,
							onCellEvent: onCellEventStories)
						{ item, _ in
							StoryView(post: item)
					})
						.layout(scrollDirection: .horizontal)
					{
						.list(itemSize: .absolute(100), sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
					}
					.frame(height: 100)
					.scrollIndicatorsEnabled(false)
				}
			}
			else
			{
				return ASTableViewSection(
					id: i,
					data: sectionData,
					estimatedItemSize: CGSize(width: 0, height: 500),
					onCellEvent: onCellEventPosts)
				{ item, _ in
					PostView(post: item)
				}
			}
		}
	}

	var body: some View
	{
		ASTableView(sections: sections)
			.tableViewSeparatorsEnabled(false)
			.onTableViewReachedBottom
		{
			self.loadMoreContent() // REACHED BOTTOM, LOADING MORE CONTENT
		}
		.navigationBarTitle("Insta Feed (tableview)", displayMode: .inline)
	}

	func loadMoreContent()
	{
		let a = data.count
		data.append(DataSource.postsForSection(a))
	}

	func onCellEventStories(_ event: CellEvent<Post>)
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

	func onCellEventPosts(_ event: CellEvent<Post>)
	{
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
