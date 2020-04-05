// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI

struct RemindersScreen: View
{
	enum Section
	{
		case upper
		case list
		case addNew
		case footnote
	}

	var upperData: [GroupModel] = [GroupModel(icon: "calendar", title: "Today", color: .blue),
								   GroupModel(icon: "clock.fill", title: "Scheduled", color: .orange),
								   GroupModel(icon: "tray.fill", title: "All", color: .gray),
								   GroupModel(icon: "flag.fill", title: "Flagged", color: .red)]
	var lowerData: [GroupModel] = [GroupModel(icon: "list.bullet", title: "Todo"),
								   GroupModel(icon: "cart.fill", title: "Groceries"),
								   GroupModel(icon: "house.fill", title: "House renovation"),
								   GroupModel(icon: "book.fill", title: "Reading list")]

	let addNewModel = GroupModel(icon: "plus", title: "Create new list", contentCount: nil, color: .green)

	var body: some View
	{
		ASCollectionView
		{
			ASCollectionViewSection<Section>(id: .upper, data: self.upperData)
			{ model, _ in
				GroupLarge(model: model)
			}

			ASCollectionViewSection<Section>(id: .list, data: self.lowerData)
			{ model, info in
				VStack(spacing: 0)
				{
					GroupSmall(model: model)
					if !info.isLastInSection
					{
						Divider()
					}
				}
			}
			.sectionHeader
			{
				Text("My Lists")
					.font(.headline)
					.bold()
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
			}

			ASCollectionViewSection<Section>(id: .addNew)
			{
				GroupSmall(model: self.addNewModel)
			}

			ASCollectionViewSection<Section>(id: .footnote)
			{
				Text("Try rotating the screen")
					.padding()
					.frame(maxWidth: .infinity, alignment: .center)
			}
		}
		.layout(self.layout)
		.contentInsets(.init(top: 20, left: 0, bottom: 20, right: 0))
		.alwaysBounceVertical()
		.background(Color(.systemGroupedBackground))
		.edgesIgnoringSafeArea(.all)
		.navigationBarTitle("Reminders", displayMode: .inline)
	}

	let groupBackgroundElementID = UUID().uuidString

	var layout: ASCollectionLayout<Section>
	{
		ASCollectionLayout<Section>(interSectionSpacing: 20)
		{ sectionID in
			switch sectionID
			{
			case .upper:
				return .grid(
					layoutMode: .adaptive(withMinItemSize: 165),
					itemSpacing: 20,
					lineSpacing: 20,
					itemSize: .estimated(90))
			case .list, .addNew, .footnote:
				return ASCollectionLayoutSection
				{
					let itemSize = NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: .estimated(60))
					let item = NSCollectionLayoutItem(layoutSize: itemSize)

					let groupSize = NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: .estimated(60))
					let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

					let section = NSCollectionLayoutSection(group: group)
					section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

					let supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
					let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
						layoutSize: supplementarySize,
						elementKind: UICollectionView.elementKindSectionHeader,
						alignment: .top)
					let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
						layoutSize: supplementarySize,
						elementKind: UICollectionView.elementKindSectionFooter,
						alignment: .bottom)
					section.boundarySupplementaryItems = [headerSupplementary, footerSupplementary]

					let sectionBackgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: self.groupBackgroundElementID)
					sectionBackgroundDecoration.contentInsets = section.contentInsets
					section.decorationItems = [sectionBackgroundDecoration]

					return section
				}
			}
		}
		.decorationView(GroupBackground.self, forDecorationViewOfKind: groupBackgroundElementID)
	}
}

struct GroupBackground: View, Decoration
{
	let cornerRadius: CGFloat = 12
	var body: some View
	{
		RoundedRectangle(cornerRadius: cornerRadius)
			.fill(Color(.secondarySystemGroupedBackground))
	}
}

struct RemindersScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		RemindersScreen()
	}
}
