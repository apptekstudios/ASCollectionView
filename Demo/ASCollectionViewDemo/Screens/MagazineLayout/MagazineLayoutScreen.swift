// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import MagazineLayout
import SwiftUI
import UIKit

struct MagazineLayoutScreen: View
{
	@State var data: [[Post]] = (0 ... 5).map
	{
		DataSource.postsForGridSection($0, number: 10)
	}

	var sections: [ASCollectionViewSection<Int>]
	{
		data.enumerated().map
		{ (offset, sectionData) -> ASCollectionViewSection<Int> in
			ASCollectionViewSection(
				id: offset,
				data: sectionData,
				onCellEvent: onCellEvent,
				contextMenuProvider: contextMenuProvider)
			{ item, _ in
				ASRemoteImageView(item.url)
					.aspectRatio(1, contentMode: .fit)
			}
			.sectionSupplementary(ofKind: MagazineLayout.SupplementaryViewKind.sectionHeader)
			{
				Text("Section \(offset)")
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color.blue)
			}
		}
	}

	var body: some View
	{
		ASCollectionView(sections: self.sections)
			.layout { MagazineLayout() }
			.onReachedBoundary { boundary in
				print("Reached the \(boundary) boundary")
			}
			.customDelegate(ASCollectionViewMagazineLayoutDelegate.init)
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("Magazine Layout (custom delegate)", displayMode: .inline)
	}

	func onCellEvent(_ event: CellEvent<Post>)
	{
		switch event
		{
		case let .onAppear(item):
			ASRemoteImageManager.shared.load(item.url)
		case let .onDisappear(item):
			ASRemoteImageManager.shared.cancelLoad(for: item.url)
		case let .prefetchForData(data):
			for item in data
			{
				ASRemoteImageManager.shared.load(item.url)
			}
		case let .cancelPrefetchForData(data):
			for item in data
			{
				ASRemoteImageManager.shared.cancelLoad(for: item.url)
			}
		}
	}

	func contextMenuProvider(index: Int, post: Post) -> UIContextMenuConfiguration?
	{
		let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) -> UIMenu? in
			let testAction = UIAction(title: "Test") { _ in
				//
			}
			return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [testAction])
		}
		return configuration
	}
}

struct MagazineLayoutScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		MagazineLayoutScreen()
	}
}
