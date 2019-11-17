// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

struct PhotoGridScreen: View
{
	var startingAtBottom: Bool = false

	@State var data: [Post] = DataSource.postsForGridSection(1, number: 1000)
	@State var selectedItems: IndexSet = []

	@Environment(\.editMode) private var editMode
	var isEditing: Bool
	{
		editMode?.wrappedValue.isEditing ?? false
	}

	typealias SectionID = Int

	var section: ASCollectionViewSection<SectionID>
	{
		ASCollectionViewSection(
			id: 0,
			data: data,
			onCellEvent: onCellEvent,
			onDragDropEvent: onDragDropEvent,
			itemProvider: { item in
				// Example of returning a custom item provider (eg. to support drag-drop to other apps)
				NSItemProvider(object: item.url as NSURL)
		})
		{ item, state in
			ZStack(alignment: .bottomTrailing)
			{
				GeometryReader
				{ geom in
					ASRemoteImageView(item.squareThumbURL)
						.aspectRatio(1, contentMode: .fill)
						.frame(width: geom.size.width, height: geom.size.height)
						.clipped()
						.opacity(state.isSelected ? 0.7 : 1.0)
				}

				if state.isSelected
				{
					ZStack
					{
						Circle()
							.fill(Color.blue)
						Circle()
							.strokeBorder(Color.white, lineWidth: 2)
						Image(systemName: "checkmark")
							.font(.system(size: 10, weight: .bold))
							.foregroundColor(.white)
					}
					.frame(width: 20, height: 20)
					.padding(10)
				}
			}
		}
	}

	var body: some View
	{
		ASCollectionView(
			selectedItems: $selectedItems,
			section: section)
			.layout(self.layout)
			.initialScrollPosition(startingAtBottom ? .bottom : nil)
			.navigationBarTitle("Explore", displayMode: .inline)
			.navigationBarItems(
				trailing:
				HStack(spacing: 20)
				{
					if self.isEditing
					{
						Button(action: {
							self.data.remove(atOffsets: self.selectedItems)
						})
						{
							Image(systemName: "trash")
						}
					}

					EditButton()
			})
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

	func onDragDropEvent(_ event: DragDrop<Post>)
	{
		switch event
		{
		case let .onRemoveItem(indexPath):
			data.remove(at: indexPath.item)
		case let .onAddItems(items, indexPath):
			data.insert(contentsOf: items, at: indexPath.item)
		}
	}
}

extension PhotoGridScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0)
		{
			ASCollectionLayoutSection
			{ environment in
				let isWide = environment.container.effectiveContentSize.width > 500
				let gridBlockSize = environment.container.effectiveContentSize.width / (isWide ? 5 : 3)
				let gridItemInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
				let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				item.contentInsets = gridItemInsets
				let verticalGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize * 2))
				let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: verticalGroupSize, subitem: item, count: 2)

				let featureItemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize * 2), heightDimension: .absolute(gridBlockSize * 2))
				let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)
				featureItem.contentInsets = gridItemInsets

				let fullWidthItemSize = NSCollectionLayoutSize(widthDimension: .absolute(environment.container.effectiveContentSize.width), heightDimension: .absolute(gridBlockSize * 2))
				let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)
				fullWidthItem.contentInsets = gridItemInsets

				let verticalAndFeatureGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 2))
				let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, verticalGroup, featureItem, verticalGroup] : [verticalGroup, featureItem])
				let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, featureItem, verticalGroup, verticalGroup] : [featureItem, verticalGroup])

				let rowGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize))
				let rowGroup = NSCollectionLayoutGroup.horizontal(layoutSize: rowGroupSize, subitem: item, count: isWide ? 5 : 3)

				let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 8))
				let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitems: [verticalAndFeatureGroupA, rowGroup, fullWidthItem, verticalAndFeatureGroupB, rowGroup])

				let section = NSCollectionLayoutSection(group: outerGroup)
				return section
			}
		}
	}
}

struct GridView_Previews: PreviewProvider
{
	static var previews: some View
	{
		PhotoGridScreen()
	}
}
