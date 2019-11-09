// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

class LayoutState: ObservableObject {
	@Published
	var numberOfColumns: Int = 3
	
	var safeNumberOfColumns: Int {
		max(1, numberOfColumns)
	}
}

struct AdjustableGridScreen: View
{
	@ObservedObject var layoutState = LayoutState()
	@State var data: [Post] = DataSource.postsForSection(1, number: 1000)
	@State var selectedItems: [SectionID: IndexSet] = [:]

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
			onCellEvent: onCellEvent)
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
		VStack {
			Stepper("Number of columns", value: self.$layoutState.numberOfColumns)
				.padding()
			ASCollectionView(
				selectedItems: $selectedItems,
				sections: [section])
				.layout(self.layout)
				.shouldInvalidateLayoutOnStateChange(true)
				.navigationBarTitle("Explore", displayMode: .inline)
				.navigationBarItems(
					trailing:
					HStack(spacing: 20)
					{
						if self.isEditing
						{
							Button(action: {
								if let (_, indexSet) = self.selectedItems.first
								{
									self.data.remove(atOffsets: indexSet)
								}
							})
							{
								Image(systemName: "trash")
							}
						}
						
						EditButton()
				})
		}
		
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

extension AdjustableGridScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0)
		{
			ASCollectionLayoutSection.grid(layoutMode: .fixedNumberOfColumns(self.layoutState.safeNumberOfColumns))
		}
	}
}
