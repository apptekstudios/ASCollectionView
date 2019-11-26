// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

/// THIS IS A WORK IN PROGRESS
struct WaterfallScreen: View
{
	@State var data: [Post] = DataSource.postsForWaterfallSection(1, number: 1000)
	@State var selectedItems: [SectionID: IndexSet] = [:]
	@State var columnMinSize: CGFloat = 150

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
			GeometryReader
			{ geom in
				ZStack(alignment: .bottomTrailing)
				{
					ASRemoteImageView(item.squareThumbURL)
						.scaledToFill()
						.frame(width: geom.size.width, height: geom.size.height)
						.opacity(state.isSelected ? 0.7 : 1.0)

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
					else
					{
						Text("\(item.offset)")
							.font(.title)
							.bold()
							.padding(2)
							.background(Color(.systemBackground).opacity(0.5))
							.cornerRadius(4)
							.padding(10)
					}
				}
				.frame(width: geom.size.width, height: geom.size.height)
				.clipped()
			}
		}
	}

	var body: some View
	{
		VStack(spacing: 0)
		{
			if self.isEditing
			{
				HStack
				{
					Text("Min. column size")
					Slider(value: self.$columnMinSize, in: 60...200)
				}.padding()
			}

			ASCollectionView(
				selectedItems: $selectedItems,
				sections: [section])
				.layout(self.layout)
				.customDelegate(WaterfallScreenLayoutDelegate.init)
				.contentInsets(.init(top: 0, left: 10, bottom: 10, right: 10))
				.navigationBarTitle("Waterfall Layout", displayMode: .inline)
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

extension WaterfallScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(createCustomLayout: ASWaterfallLayout.init)
		{ layout in
			layout.numberOfColumns = .adaptive(minWidth: self.columnMinSize)
		}
		// Can also initialise like this when no need to dynamically update values
		/*
		 ASCollectionLayout
		 {
		 	let layout = ASWaterfallLayout()
		 	return layout
		 }
		 */
	}
}

struct WaterfallScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		WaterfallScreen()
	}
}

class WaterfallScreenLayoutDelegate: ASCollectionViewDelegate, ASWaterfallLayoutDelegate
{
	/// We explicitely provide a height here. If providing no delegate, this layout will use auto-sizing, however this causes problems if rotating the device (due to limitaitons in UICollecitonView and autosizing cells that are not visible)
	func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat
	{
		guard let post: Post = getDataForItem(at: indexPath) else { return 100 }
		return context.width / post.aspectRatio
	}
}
