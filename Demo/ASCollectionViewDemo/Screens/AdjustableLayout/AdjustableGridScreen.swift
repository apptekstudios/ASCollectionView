// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

class LayoutState: ObservableObject
{
	@Published
	var numberOfColumns: Int = 3

	@Published
	var itemInset: Int = 0
}

struct AdjustableGridScreen: View
{
	@ObservedObject var layoutState = LayoutState()
	@State var showConfig: Bool = true
	@State var data: [Post] = DataSource.postsForGridSection(1, number: 1000)

	typealias SectionID = Int

	var section: ASCollectionViewSection<SectionID>
	{
		ASCollectionViewSection(
			id: 0,
			data: data,
			onCellEvent: onCellEvent)
		{ item, state in
			ZStack(alignment: .bottomTrailing)
			{
				GeometryReader
				{ geom in
					ASRemoteImageView(item.url)
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

	var config: some View
	{
		VStack
		{
			Stepper("Number of columns", value: self.$layoutState.numberOfColumns, in: 1 ... 10)
				.padding()
			Stepper("Item inset", value: self.$layoutState.itemInset, in: 0 ... 5)
				.padding()
		}
	}

	var body: some View
	{
		VStack
		{
			if showConfig
			{
				config
			}
			ASCollectionView(
				section: section)
				.layout(self.layout)
				.shouldInvalidateLayoutOnStateChange(true)
				.navigationBarTitle("Adjustable Layout", displayMode: .inline)
		}
		.navigationBarItems(
			trailing:
			Button(action: {
				self.showConfig.toggle()
			})
			{
				Text("Toggle config")
		})
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
}

extension AdjustableGridScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0)
		{
			ASCollectionLayoutSection
			{
				let gridBlockSize = NSCollectionLayoutDimension.fractionalWidth(1 / CGFloat(self.layoutState.numberOfColumns))
				let item = NSCollectionLayoutItem(
					layoutSize: NSCollectionLayoutSize(
						widthDimension: gridBlockSize,
						heightDimension: .fractionalHeight(1.0)))
				let inset = CGFloat(self.layoutState.itemInset)
				item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

				let itemsGroup = NSCollectionLayoutGroup.horizontal(
					layoutSize: NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: gridBlockSize),
					subitems: [item])

				let section = NSCollectionLayoutSection(group: itemsGroup)
				return section
			}
		}
	}
}
