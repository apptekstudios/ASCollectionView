// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI

struct AppStoreScreen: View
{
	@State var data: [(sectionTitle: String, apps: [App])] = (0 ... 20).map
	{
		(Lorem.title, DataSource.appsForSection($0))
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
		}
	}

	var sections: [ASCollectionViewSection<Int>]
	{
		data.enumerated().map
		{ (sectionID, sectionData) -> ASCollectionViewSection<Int> in
			ASCollectionViewSection(
				id: sectionID,
				data: sectionData.apps,
				onCellEvent: {
					self.onCellEvent($0, sectionID: sectionID)
			})
			{ item, _ in
				if sectionID == 0
				{
					AppViewFeature(app: item)
				}
				else if sectionID == 1
				{
					AppViewLarge(app: item)
				}
				else
				{
					AppViewCompact(app: item)
				}
			}
			.sectionHeader
			{
				self.header(withTitle: sectionData.sectionTitle)
			}
		}
	}

	var body: some View
	{
		ASCollectionView(sections: self.sections)
			.layout(self.layout)
			.shouldAttemptToMaintainScrollPositionOnOrientationChange(maintainPosition: false)
			.navigationBarTitle("Apps", displayMode: .large)
			.edgesIgnoringSafeArea(.all)
	}

	func onCellEvent(_ event: CellEvent<App>, sectionID: Int)
	{
		switch event
		{
		case let .onAppear(item):
			switch sectionID
			{
			case 0:
				ASRemoteImageManager.shared.load(item.featureImageURL)
			default:
				ASRemoteImageManager.shared.load(item.url)
			}
		case let .onDisappear(item):
			switch sectionID
			{
			case 0:
				ASRemoteImageManager.shared.cancelLoad(for: item.featureImageURL)
			default:
				ASRemoteImageManager.shared.cancelLoad(for: item.url)
			}
		case let .prefetchForData(data):
			for item in data
			{
				switch sectionID
				{
				case 0:
					ASRemoteImageManager.shared.load(item.featureImageURL)
				default:
					ASRemoteImageManager.shared.load(item.url)
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
					ASRemoteImageManager.shared.cancelLoad(for: item.url)
				}
			}
		}
	}
}

extension AppStoreScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 20)
		{ sectionID in
			switch sectionID
			{
			case 0:
				return ASCollectionLayoutSection
				{ environment in
					let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
					let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: .fractionalHeight(1.0)))

					let itemsGroup = NSCollectionLayoutGroup.vertical(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(0.8 / columnsToFit),
							heightDimension: .absolute(280)),
						subitem: item, count: 1)

					let section = NSCollectionLayoutSection(group: itemsGroup)
					section.interGroupSpacing = 20
					section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
					section.orthogonalScrollingBehavior = .groupPaging
					return section
				}
			case 1:
				return ASCollectionLayoutSection
				{ environment in
					let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
					let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: .fractionalHeight(1.0)))

					let itemsGroup = NSCollectionLayoutGroup.vertical(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(1.0),
							heightDimension: .fractionalHeight(1.0)),
						subitem: item, count: 2)
					itemsGroup.interItemSpacing = .fixed(10)

					let nestedGroup = NSCollectionLayoutGroup.horizontal(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(0.9 / columnsToFit),
							heightDimension: .absolute(180)),
						subitems: [itemsGroup])
					nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

					let header = NSCollectionLayoutBoundarySupplementaryItem(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(1.0),
							heightDimension: .absolute(34)),
						elementKind: UICollectionView.elementKindSectionHeader,
						alignment: .top)
					header.contentInsets.leading = nestedGroup.contentInsets.leading
					header.contentInsets.trailing = nestedGroup.contentInsets.trailing

					let section = NSCollectionLayoutSection(group: nestedGroup)
					section.boundarySupplementaryItems = [header]
					section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
					section.orthogonalScrollingBehavior = .groupPaging
					return section
				}
			default:
				return ASCollectionLayoutSection
				{ environment in
					let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
					let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: .fractionalHeight(1.0)))

					let itemsGroup = NSCollectionLayoutGroup.vertical(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(1.0),
							heightDimension: .fractionalHeight(1.0)),
						subitem: item, count: 3)
					itemsGroup.interItemSpacing = .fixed(10)

					let nestedGroup = NSCollectionLayoutGroup.horizontal(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(0.9 / columnsToFit),
							heightDimension: .absolute(240)),
						subitems: [itemsGroup])
					nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

					let header = NSCollectionLayoutBoundarySupplementaryItem(
						layoutSize: NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(1.0),
							heightDimension: .absolute(34)),
						elementKind: UICollectionView.elementKindSectionHeader,
						alignment: .top)
					header.contentInsets.leading = nestedGroup.contentInsets.leading
					header.contentInsets.trailing = nestedGroup.contentInsets.trailing

					let section = NSCollectionLayoutSection(group: nestedGroup)
					section.boundarySupplementaryItems = [header]
					section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
					section.orthogonalScrollingBehavior = .groupPaging
					return section
				}
			}
		}
	}
}

struct AppStoreScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		AppStoreScreen()
	}
}
