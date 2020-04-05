// ASCollectionView. Created by Apptek Studios 2019

// This file is built with the demo project to ensure the sample code used in the readme is valid

import ASCollectionView
import SwiftUI

struct READMEContent
{
	// MARK: EXAMPLE 1

	struct SingleSectionExampleView: View
	{
		@State var dataExample = (0 ..< 30).map { $0 }

		var body: some View
		{
			ASCollectionView(data: dataExample, dataID: \.self) { item, _ in
				Color.blue
					.overlay(Text("\(item)"))
			}
			.layout {
				.grid(
					layoutMode: .adaptive(withMinItemSize: 100),
					itemSpacing: 5,
					lineSpacing: 5,
					itemSize: .absolute(50))
			}
		}
	}

	// MARK: EXAMPLE 2

	struct ExampleView: View
	{
		@State var dataExampleA = (0 ..< 21).map { $0 }
		@State var dataExampleB = (0 ..< 15).map { "ITEM \($0)" }

		var body: some View
		{
			ASCollectionView
			{
				ASCollectionViewSection(
					id: 0,
					data: dataExampleA,
					dataID: \.self)
				{ item, _ in
					Color.blue
						.overlay(
							Text("\(item)")
						)
				}
				ASCollectionViewSection(
					id: 1,
					data: dataExampleB,
					dataID: \.self)
				{ item, _ in
					Color.green
						.overlay(
							Text("Complex layout - \(item)")
						)
				}
				.sectionHeader
				{
					Text("Section header")
						.padding()
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(Color.yellow)
				}
				.sectionFooter
				{
					Text("This is a section footer!")
						.padding()
				}
			}
			.layout { sectionID in
				switch sectionID
				{
				default:
					return .grid(
						layoutMode: .adaptive(withMinItemSize: 100),
						itemSpacing: 5,
						lineSpacing: 5,
						itemSize: .absolute(50))
				}
			}
		}
	}

	var sectionHeaderExample: ASCollectionViewSection<Int>
	{
		ASCollectionViewSection(id: 0) {
			Text("Cell 1")
			Text("Cell 2")
		}
		.sectionHeader
		{
			Text("Section header")
				.background(Color.yellow)
		}
		.sectionFooter
		{
			Text("Section footer")
				.background(Color.blue)
		}
		.sectionSupplementary(ofKind: "someOtherSupplementaryKindRequestedByYourLayout") {
			Text("Section supplementary")
				.background(Color.green)
		}
	}

	// MARK: DecorationView Example

	struct GroupBackground: View, Decoration
	{
		let cornerRadius: CGFloat = 12
		var body: some View
		{
			RoundedRectangle(cornerRadius: cornerRadius)
				.fill(Color(.secondarySystemGroupedBackground))
		}
	}
}
