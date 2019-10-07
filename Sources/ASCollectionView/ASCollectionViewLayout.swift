// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

public struct ASCollectionViewLayout<SectionID: Hashable>
{
	enum LayoutType
	{
		case compositional(CompositionalLayout, interSectionSpacing: CGFloat, scrollDirection: UICollectionView.ScrollDirection)
		case custom(UICollectionViewLayout)
	}

	var layout: LayoutType
	typealias CompositionalLayout = ((_ sectionID: SectionID) -> ASCollectionViewLayoutSection)

	public init(scrollDirection: UICollectionView.ScrollDirection = .vertical,
	            interSectionSpacing: CGFloat = 10,
	            layoutPerSection: @escaping ((_ sectionID: SectionID) -> ASCollectionViewLayoutSection))
	{
		layout = .compositional(layoutPerSection, interSectionSpacing: interSectionSpacing, scrollDirection: scrollDirection)
	}

	public init(scrollDirection: UICollectionView.ScrollDirection = .vertical,
	            interSectionSpacing: CGFloat = 10,
	            layout: ASCollectionViewLayoutSection)
	{
		self.layout = .compositional({ _ in layout }, interSectionSpacing: interSectionSpacing, scrollDirection: scrollDirection) // ignore section ID -> all have same layout
	}

	public init(layout: UICollectionViewLayout)
	{
		self.layout = .custom(layout)
	}

	public func makeLayout(withCoordinator coordinator: ASCollectionView<SectionID>.Coordinator) -> UICollectionViewLayout
	{
		switch layout
		{
		case let .custom(layout):
			return layout
		case let .compositional(layoutClosure, interSectionSpacing, scrollDirection):
			let config = UICollectionViewCompositionalLayoutConfiguration()
			config.scrollDirection = scrollDirection
			config.interSectionSpacing = interSectionSpacing

			let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection in
				let sectionID = coordinator.sectionID(fromSectionIndex: sectionIndex)
				let sectionLayout = layoutClosure(sectionID)
				return sectionLayout.makeLayout(in: layoutEnvironment, primaryScrollDirection: scrollDirection)
			}

			let cvLayout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
			return cvLayout
		}
	}

	public static var `default`: ASCollectionViewLayout<SectionID>
	{
		ASCollectionViewLayout(layout: ASCollectionViewLayoutList())
	}
}

public protocol ASCollectionViewLayoutSection
{
	func makeLayout(in layoutEnvironment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
}

public struct ASCollectionViewLayoutCustomCompositionalSection: ASCollectionViewLayoutSection
{
	public typealias SectionLayout = ((_ layoutEnvironment: NSCollectionLayoutEnvironment, _ primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection)
	var makeLayoutClosure: SectionLayout

	public init(sectionLayout: @escaping SectionLayout)
	{
		makeLayoutClosure = sectionLayout
	}

	public func makeLayout(in layoutEnvironment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		makeLayoutClosure(layoutEnvironment, primaryScrollDirection)
	}
}

public struct ASCollectionViewLayoutList: ASCollectionViewLayoutSection
{
	var itemSize: NSCollectionLayoutDimension
	var spacing: CGFloat
	var sectionInsets: NSDirectionalEdgeInsets

	public init(itemSize: NSCollectionLayoutDimension = .estimated(200),
	            spacing: CGFloat = 5,
	            sectionInsets: NSDirectionalEdgeInsets = .zero)
	{
		self.itemSize = itemSize
		self.spacing = spacing
		self.sectionInsets = sectionInsets
	}

	public func makeLayout(in layoutEnvironment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		let itemLayoutSize: NSCollectionLayoutSize
		let groupSize: NSCollectionLayoutSize
		let headerSize: NSCollectionLayoutSize

		switch primaryScrollDirection
		{
		case .horizontal:
			itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
			groupSize = NSCollectionLayoutSize(widthDimension: itemSize, heightDimension: .fractionalHeight(1.0))
			headerSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
		case .vertical: fallthrough
		@unknown default:
			itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
			groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
			headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
		}

		let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

		let section = NSCollectionLayoutSection(group: group)
		section.contentInsets = sectionInsets
		section.interGroupSpacing = spacing

		let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
		                                                                      elementKind: UICollectionView.elementKindSectionHeader,
		                                                                      alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
		section.boundarySupplementaryItems = [headerSupplementary]
		return section
	}
}

public struct ASCollectionViewLayoutFlow: ASCollectionViewLayoutSection
{
	var itemSpacing: CGFloat = 5
	var lineSpacing: CGFloat = 5

	public func makeLayout(in layoutEnvironment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		let itemSize: NSCollectionLayoutSize
		let groupSize: NSCollectionLayoutSize
		let headerSize: NSCollectionLayoutSize

		switch primaryScrollDirection
		{
		case .horizontal:
			itemSize = NSCollectionLayoutSize(widthDimension: .estimated(150), heightDimension: .estimated(50))
			groupSize = NSCollectionLayoutSize(widthDimension: .estimated(150), heightDimension: .fractionalHeight(1.0))
			headerSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
		case .vertical: fallthrough
		@unknown default:
			itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .estimated(55))
			groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(55))
			headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
		}

		let item = NSCollectionLayoutItem(layoutSize: itemSize)
		let group: NSCollectionLayoutGroup

		if primaryScrollDirection == .horizontal
		{
			group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
		}
		else
		{
			group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
		}
		group.interItemSpacing = .fixed(itemSpacing)

		let section = NSCollectionLayoutSection(group: group)
		section.interGroupSpacing = lineSpacing

		let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
		                                                                      elementKind: UICollectionView.elementKindSectionHeader,
		                                                                      alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
		section.boundarySupplementaryItems = [headerSupplementary]
		return section
	}
}

public struct ASCollectionViewLayoutGrid: ASCollectionViewLayoutSection
{
	var layoutMode: LayoutMode = .fixedNumberOfColumns(2)
	var itemSpacing: CGFloat = 5
	var lineSpacing: CGFloat = 5
	var itemSize: NSCollectionLayoutDimension = .estimated(150)

	enum LayoutMode
	{
		case fixedNumberOfColumns(Int)
		case adaptive(withMinItemSize: CGFloat)
	}

	public func makeLayout(in layoutEnvironment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		let count: Int = {
			switch self.layoutMode
			{
			case let .fixedNumberOfColumns(count):
				return count
			case let .adaptive(minItemSize):
				let containerSize = (primaryScrollDirection == .horizontal) ? layoutEnvironment.container.effectiveContentSize.height : layoutEnvironment.container.effectiveContentSize.width
				return max(1, Int(containerSize / minItemSize))
			}
		}()

		let itemLayoutSize: NSCollectionLayoutSize
		let groupSize: NSCollectionLayoutSize
		let headerSize: NSCollectionLayoutSize

		switch primaryScrollDirection
		{
		case .horizontal:
			itemLayoutSize = NSCollectionLayoutSize(widthDimension: itemSize, heightDimension: .fractionalHeight(1.0))
			groupSize = NSCollectionLayoutSize(widthDimension: itemSize, heightDimension: .fractionalHeight(1.0))
			headerSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
		case .vertical: fallthrough
		@unknown default:
			itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
			groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
			headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
		}
		let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)

		let group: NSCollectionLayoutGroup
		if primaryScrollDirection == .horizontal
		{
			group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: count)
		}
		else
		{
			group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
		}
		group.interItemSpacing = .fixed(itemSpacing)

		let section = NSCollectionLayoutSection(group: group)
		section.interGroupSpacing = lineSpacing

		let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
		                                                                      elementKind: UICollectionView.elementKindSectionHeader,
		                                                                      alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
		section.boundarySupplementaryItems = [headerSupplementary]
		return section
	}
}

public struct ASCollectionViewLayoutOrthogonalGrid: ASCollectionViewLayoutSection
{
	public var gridSize: Int = 2
	public var itemDimension: NSCollectionLayoutDimension = .fractionalWidth(0.9)
	public var sectionDimension: NSCollectionLayoutDimension = .fractionalHeight(0.8)
	public var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .groupPagingCentered
	public var gridSpacing: CGFloat = 5
	public var itemInsets: NSDirectionalEdgeInsets = .zero
	public var sectionInsets: NSDirectionalEdgeInsets = .zero

	public init()
	{}

	public func makeLayout(in layoutEnvironment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		let orthogonalScrollDirection: UICollectionView.ScrollDirection = (primaryScrollDirection == .vertical) ? .horizontal : .vertical

		let itemSize: NSCollectionLayoutSize
		let groupSize: NSCollectionLayoutSize
		let headerSize: NSCollectionLayoutSize

		switch primaryScrollDirection
		{
		case .horizontal:
			headerSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
		case .vertical: fallthrough
		@unknown default:
			headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
		}
		switch orthogonalScrollDirection
		{
		case .horizontal:
			itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
			groupSize = NSCollectionLayoutSize(widthDimension: itemDimension, heightDimension: sectionDimension)
		case .vertical: fallthrough
		@unknown default:
			itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
			groupSize = NSCollectionLayoutSize(widthDimension: sectionDimension, heightDimension: itemDimension)
		}
		let item = NSCollectionLayoutItem(layoutSize: itemSize)

		let group: NSCollectionLayoutGroup
		if orthogonalScrollDirection == .horizontal
		{
			group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: gridSize)
		}
		else
		{
			group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: gridSize)
		}
		group.interItemSpacing = .fixed(gridSpacing)
		group.contentInsets = itemInsets

		let section = NSCollectionLayoutSection(group: group)
		section.orthogonalScrollingBehavior = orthogonalScrollingBehavior
		section.contentInsets = sectionInsets

		let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
		                                                                      elementKind: UICollectionView.elementKindSectionHeader,
		                                                                      alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
		headerSupplementary.contentInsets = itemInsets

		section.boundarySupplementaryItems = [headerSupplementary]
		return section
	}
}
