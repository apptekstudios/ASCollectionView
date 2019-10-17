// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

struct GridView: View
{
	@State var data: [[Post]] = [DataSource.postsForSection(1, number: 1000)]

	var layout: ASCollectionViewLayout<Int>
	{
		ASCollectionViewLayout(scrollDirection: .vertical, interSectionSpacing: 0, layout: ASCollectionViewLayoutCustomCompositionalSection(sectionLayout: { (layoutEnvironment, _) -> NSCollectionLayoutSection in
			let isWide = layoutEnvironment.container.effectiveContentSize.width > 500
			let gridBlockSize = layoutEnvironment.container.effectiveContentSize.width / (isWide ? 5 : 3)
			let gridItemInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
			let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			item.contentInsets = gridItemInsets
			let verticalGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize * 2))
			let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: verticalGroupSize, subitem: item, count: 2)

			let featureItemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize * 2), heightDimension: .absolute(gridBlockSize * 2))
			let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)
			featureItem.contentInsets = gridItemInsets

			let verticalAndFeatureGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 2))
			let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, verticalGroup, featureItem, verticalGroup] : [verticalGroup, featureItem])
			let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, featureItem, verticalGroup, verticalGroup] : [featureItem, verticalGroup])

			let rowGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize))
			let rowGroup = NSCollectionLayoutGroup.horizontal(layoutSize: rowGroupSize, subitem: item, count: isWide ? 5 : 3)

			let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 6))
			let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitems: [verticalAndFeatureGroupA, rowGroup, verticalAndFeatureGroupB, rowGroup])

			let section = NSCollectionLayoutSection(group: outerGroup)
			return section
		}))
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
					.aspectRatio(1, contentMode: .fill)
                    .contextMenu {
                        Text("Test item")
                        Text("Another item")
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
				.navigationBarTitle("Explore", displayMode: .inline)
		}.navigationViewStyle(StackNavigationViewStyle())
	}
}

struct GridView_Previews: PreviewProvider
{
	static var previews: some View
	{
		GridView()
	}
}
