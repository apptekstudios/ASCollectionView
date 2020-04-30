// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

/// If building a custom layout, you can conform to this protocol to tell ASCollectionLayout which dimensions should be self-sized (default is both)
@available(iOS 13.0, *)
public protocol ASCollectionViewLayoutProtocol
{
	var selfSizingConfig: ASSelfSizingConfig { get }
}

// MARK: Public Typealias for layout closures

@available(iOS 13.0, *)
public typealias CompositionalLayout<SectionID: Hashable> = ((_ sectionID: SectionID) -> ASCollectionLayoutSection)

@available(iOS 13.0, *)
public typealias CompositionalLayoutIgnoringSections = (() -> ASCollectionLayoutSection)

@available(iOS 13.0, *)
public struct ASCollectionLayout<SectionID: Hashable>
{
	enum LayoutType
	{
		case compositional(CompositionalLayout<SectionID>, interSectionSpacing: CGFloat, scrollDirection: UICollectionView.ScrollDirection)
		case custom(UICollectionViewLayout)
	}

	var layout: LayoutType
	var configureLayout: ((UICollectionViewLayout) -> Void)?
	var decorationTypes: [(elementKind: String, ViewType: UICollectionReusableView.Type)] = []

	public init(
		scrollDirection: UICollectionView.ScrollDirection = .vertical,
		interSectionSpacing: CGFloat = 10,
		layoutPerSection: @escaping CompositionalLayout<SectionID>)
	{
		layout = .compositional(layoutPerSection, interSectionSpacing: interSectionSpacing, scrollDirection: scrollDirection)
	}

	public init(
		scrollDirection: UICollectionView.ScrollDirection = .vertical,
		interSectionSpacing: CGFloat = 10,
		layout: @escaping CompositionalLayoutIgnoringSections)
	{
		self.layout = .compositional({ _ in layout() }, interSectionSpacing: interSectionSpacing, scrollDirection: scrollDirection)
	}

	public init(customLayout: () -> UICollectionViewLayout)
	{
		layout = .custom(customLayout())
	}

	public init<LayoutClass: UICollectionViewLayout>(createCustomLayout: () -> LayoutClass, configureCustomLayout: ((LayoutClass) -> Void)?)
	{
		layout = .custom(createCustomLayout())
		configureLayout = configureCustomLayout.map
		{ configuration in
			{ layoutObject in
				guard let layoutObject = layoutObject as? LayoutClass else { return }
				configuration(layoutObject)
			}
		}
	}

	public func makeLayout(withCoordinator coordinator: ASCollectionView<SectionID>.Coordinator) -> UICollectionViewLayout
	{
		switch layout
		{
		case let .custom(layout):
			registerDecorationViews(layout)
			return layout
		case let .compositional(layoutClosure, interSectionSpacing, scrollDirection):
			let config = UICollectionViewCompositionalLayoutConfiguration()
			config.scrollDirection = scrollDirection
			config.interSectionSpacing = interSectionSpacing

			let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { [weak coordinator] sectionIndex, layoutEnvironment -> NSCollectionLayoutSection in
				guard let sectionID = coordinator?.sectionID(fromSectionIndex: sectionIndex) else { return NSCollectionLayoutSection.emptyPlaceholder(environment: layoutEnvironment, primaryScrollDirection: scrollDirection) }

				return layoutClosure(sectionID).makeLayoutSection(environment: layoutEnvironment, primaryScrollDirection: scrollDirection)
			}

			let cvLayout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
			registerDecorationViews(cvLayout)
			return cvLayout
		}
	}

	public func configureLayout(layoutObject: UICollectionViewLayout)
	{
		configureLayout?(layoutObject)
	}

	public static var `default`: ASCollectionLayout<SectionID>
	{
		ASCollectionLayout
		{
			.list()
		}
	}

	func registerDecorationViews(_ layout: UICollectionViewLayout)
	{
		decorationTypes.forEach
		{ elementKind, ViewType in
			layout.register(ViewType, forDecorationViewOfKind: elementKind)
		}
	}
}

@available(iOS 13.0, *)
private extension NSCollectionLayoutSection
{
	static func emptyPlaceholder(environment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		// Used to avoid a crash when UICollectionViewCompositionalLayout requests a NSCollectionLayoutSection for a section that no longer exists
		ASCollectionLayoutSection.list().makeLayoutSection(environment: environment, primaryScrollDirection: primaryScrollDirection)
	}
}

@available(iOS 13.0, *)
public extension ASCollectionLayout
{
	func decorationView<Content: View & Decoration>(_ viewType: Content.Type, forDecorationViewOfKind elementKind: String) -> Self
	{
		var layout = self
		layout.decorationTypes.append((elementKind, ASCollectionViewDecoration<Content>.self))
		return layout
	}
}

@available(iOS 13.0, *)
public struct ASCollectionLayoutSection
{
	public init(_ sectionLayout: @escaping () -> NSCollectionLayoutSection)
	{
		layoutSectionClosure = { _, _ in
			sectionLayout()
		}
	}

	public init(_ sectionLayout: @escaping (_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)
	{
		layoutSectionClosure = { environment, _ in
			sectionLayout(environment)
		}
	}

	init(_ sectionLayout: @escaping (_ environment: NSCollectionLayoutEnvironment, _ primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection)
	{
		layoutSectionClosure = sectionLayout
	}

	var layoutSectionClosure: (_ environment: NSCollectionLayoutEnvironment, _ primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection

	func makeLayoutSection(environment: NSCollectionLayoutEnvironment, primaryScrollDirection: UICollectionView.ScrollDirection) -> NSCollectionLayoutSection
	{
		layoutSectionClosure(environment, primaryScrollDirection)
	}
}

@available(iOS 13.0, *)
public extension ASCollectionLayoutSection
{
	static func list(
		itemSize: NSCollectionLayoutDimension = .estimated(200),
		spacing: CGFloat = 5,
		sectionInsets: NSDirectionalEdgeInsets = .zero) -> ASCollectionLayoutSection
	{
		self.init
		{ (_, primaryScrollDirection) -> NSCollectionLayoutSection in
			let itemLayoutSize: NSCollectionLayoutSize
			let groupSize: NSCollectionLayoutSize
			let supplementarySize: NSCollectionLayoutSize

			switch primaryScrollDirection
			{
			case .horizontal:
				itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
				groupSize = NSCollectionLayoutSize(widthDimension: itemSize, heightDimension: .fractionalHeight(1.0))
				supplementarySize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
			case .vertical: fallthrough
			@unknown default:
				itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
				groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
				supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
			}

			let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

			let section = NSCollectionLayoutSection(group: group)
			section.contentInsets = sectionInsets
			section.interGroupSpacing = spacing

			let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: supplementarySize,
				elementKind: UICollectionView.elementKindSectionHeader,
				alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
			let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: supplementarySize,
				elementKind: UICollectionView.elementKindSectionFooter,
				alignment: (primaryScrollDirection == .vertical) ? .bottom : .trailing)
			section.boundarySupplementaryItems = [headerSupplementary, footerSupplementary]
			return section
		}
	}
}

@available(iOS 13.0, *)
public extension ASCollectionLayoutSection
{
	enum GridLayoutMode
	{
		case fixedNumberOfColumns(Int)
		case adaptive(withMinItemSize: CGFloat)
	}

	static func grid(
		layoutMode: GridLayoutMode = .fixedNumberOfColumns(2),
		itemSpacing: CGFloat = 5,
		lineSpacing: CGFloat = 5,
		itemSize: NSCollectionLayoutDimension = .estimated(150)) -> ASCollectionLayoutSection
	{
		self.init
		{ (layoutEnvironment, primaryScrollDirection) -> NSCollectionLayoutSection in
			let count: Int = {
				switch layoutMode
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
			let supplementarySize: NSCollectionLayoutSize

			switch primaryScrollDirection
			{
			case .horizontal:
				itemLayoutSize = NSCollectionLayoutSize(widthDimension: itemSize, heightDimension: .fractionalHeight(1.0))
				groupSize = NSCollectionLayoutSize(widthDimension: itemSize, heightDimension: .fractionalHeight(1.0))
				supplementarySize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
			case .vertical: fallthrough
			@unknown default:
				itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
				groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
				supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
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
			section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)

			let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: supplementarySize,
				elementKind: UICollectionView.elementKindSectionHeader,
				alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
			let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: supplementarySize,
				elementKind: UICollectionView.elementKindSectionFooter,
				alignment: (primaryScrollDirection == .vertical) ? .bottom : .trailing)
			section.boundarySupplementaryItems = [headerSupplementary, footerSupplementary]
			return section
		}
	}
}

@available(iOS 13.0, *)
public extension ASCollectionLayoutSection
{
	static func orthogonalGrid(
		gridSize: Int = 2,
		itemDimension: NSCollectionLayoutDimension = .fractionalWidth(0.9),
		sectionDimension: NSCollectionLayoutDimension = .fractionalHeight(0.8),
		orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .groupPagingCentered,
		gridSpacing: CGFloat = 5,
		itemInsets: NSDirectionalEdgeInsets = .zero,
		sectionInsets: NSDirectionalEdgeInsets = .zero) -> ASCollectionLayoutSection
	{
		self.init
		{ (_, primaryScrollDirection) -> NSCollectionLayoutSection in
			let orthogonalScrollDirection: UICollectionView.ScrollDirection = (primaryScrollDirection == .vertical) ? .horizontal : .vertical

			let itemSize: NSCollectionLayoutSize
			let groupSize: NSCollectionLayoutSize
			let supplementarySize: NSCollectionLayoutSize

			switch primaryScrollDirection
			{
			case .horizontal:
				supplementarySize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
			case .vertical: fallthrough
			@unknown default:
				supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
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

			let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: supplementarySize,
				elementKind: UICollectionView.elementKindSectionHeader,
				alignment: (primaryScrollDirection == .vertical) ? .top : .leading)
			let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: supplementarySize,
				elementKind: UICollectionView.elementKindSectionFooter,
				alignment: (primaryScrollDirection == .vertical) ? .bottom : .trailing)
			headerSupplementary.contentInsets = itemInsets
			footerSupplementary.contentInsets = itemInsets

			section.boundarySupplementaryItems = [headerSupplementary, footerSupplementary]
			return section
		}
	}
}
