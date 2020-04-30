// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import UIKit

@available(iOS 13.0, *)
public class ASWaterfallLayout: UICollectionViewLayout, ASCollectionViewLayoutProtocol
{
	public var estimatedItemHeight: CGFloat = 400 // Only needed if using auto-sizing. SwiftUI seems to only return smaller sizes (so make this bigger than needed)
	public var estimatedHeaderHeight: CGFloat = 50

	public struct CellLayoutContext
	{
		public var width: CGFloat
	}

	public enum ColumnCount
	{
		case fixed(Int)
		case adaptive(minWidth: CGFloat)
		case perSection((Int) -> ColumnCount)
	}

	public var numberOfColumns: ColumnCount = .adaptive(minWidth: 150)
	{
		didSet
		{
			invalidateLayout()
		}
	}

	public var columnSpacing: CGFloat = 6 {
		didSet
		{
			invalidateLayout()
		}
	}

	public var sectionSpacing: CGFloat = 20 {
		didSet
		{
			invalidateLayout()
		}
	}

	public var itemSpacing: CGFloat = 6 {
		didSet
		{
			invalidateLayout()
		}
	}

	public var selfSizingConfig: ASSelfSizingConfig
	{
		ASSelfSizingConfig(
			selfSizeHorizontally: false,
			selfSizeVertically: hasDelegate ? false : true)
	}

	private var cachedHeaderHeight: [Int: CGFloat] = [:]
	private var cachedHeight: [IndexPath: CGFloat] = [:]
	private var cachedSectionHeight: [Int: CGFloat] = [:]

	private var cachedAttributes: ASIndexedDictionary<IndexPath, UICollectionViewLayoutAttributes> = .init()

	private var contentHeight: CGFloat = 0

	private var contentWidth: CGFloat
	{
		guard let collectionView = collectionView else { return 0 }
		let insets = collectionView.adjustedContentInset
		return collectionView.bounds.width - (insets.left + insets.right) - 0.0001
	}

	public override var collectionViewContentSize: CGSize
	{
		CGSize(width: contentWidth, height: contentHeight)
	}

	func calculateNumberOfColumns(sectionIndex: Int, setting: ColumnCount) -> Int
	{
		switch setting
		{
		case let .fixed(num):
			return max(1, num)
		case let .adaptive(minWidth):
			return max(1, Int(floor((contentWidth + columnSpacing) / (minWidth + columnSpacing))))
		case let .perSection(callback):
			let resolved = callback(sectionIndex)
			return calculateNumberOfColumns(sectionIndex: sectionIndex, setting: resolved)
		}
	}

	func calculateColumnWidth(sectionIndex: Int) -> CGFloat
	{
		let sectionColumnCount = calculateNumberOfColumns(sectionIndex: sectionIndex, setting: numberOfColumns)
		return (contentWidth - (columnSpacing * CGFloat(sectionColumnCount - 1))) / CGFloat(sectionColumnCount)
	}

	var hasDelegate: Bool
	{
		collectionView?.delegate is ASWaterfallLayoutDelegate
	}

	func getHeight(for indexPath: IndexPath) -> CGFloat
	{
		if let delegate = (collectionView?.delegate as? ASWaterfallLayoutDelegate)
		{
			return delegate.heightForCell(
				at: indexPath,
				context: ASWaterfallLayout.CellLayoutContext(width: calculateColumnWidth(sectionIndex: indexPath.section)))
		}
		return cachedHeight[indexPath] ?? estimatedItemHeight
	}

	func getHeightForHeader(sectionIndex: Int) -> CGFloat
	{
		if let delegate = (collectionView?.delegate as? ASWaterfallLayoutDelegate),
			let height = delegate.heightForHeader(sectionIndex: sectionIndex)
		{
			return height
		}
		return cachedHeaderHeight[sectionIndex] ?? estimatedHeaderHeight
	}

	public override func prepare()
	{
		guard let collectionView = collectionView else { return }

		// Reset cached information.
		cachedAttributes.removeAll()

		guard let sections = collectionView.allSections else { return }
		for section in sections
		{
			let sectionMinY = (0 ..< section).reduce(into: collectionView.adjustedContentInset.top) { $0 += cachedSectionHeight[$1] ?? 0 }
			var columnHeights: [CGFloat] = .init(repeating: 0, count: calculateNumberOfColumns(sectionIndex: section, setting: numberOfColumns))

			let headerHeight = getHeightForHeader(sectionIndex: section)

			// Set header attributes
			let headerIndexPath = IndexPath(item: -1, section: section)
			let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: headerIndexPath)
			headerAttributes.frame = CGRect(
				x: 0,
				y: sectionMinY,
				width: contentWidth,
				height: headerHeight)
			cachedAttributes[headerIndexPath] = headerAttributes

			let sectionContentMinY = sectionMinY + headerHeight + itemSpacing

			let sectionColumnWidth = calculateColumnWidth(sectionIndex: section)

			for indexPath in collectionView.allIndexPaths(inSection: section)
			{
				let targetColumn = columnHeights.indexOfMin() ?? 0

				let minY = sectionContentMinY + columnHeights[targetColumn]
				let sizeY = getHeight(for: indexPath)

				let minX = (sectionColumnWidth + columnSpacing) * CGFloat(targetColumn)
				let sizeX = sectionColumnWidth

				// Set cached attributes
				let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
				attributes.frame = CGRect(
					x: minX,
					y: minY,
					width: sizeX,
					height: sizeY)
				cachedAttributes.append((indexPath, attributes))

				// Update height of column
				columnHeights[targetColumn] = columnHeights[targetColumn] + sizeY + itemSpacing
			}
			cachedSectionHeight[section] = headerHeight + (columnHeights.max() ?? 0) + (section != (sections.count - 1) ? sectionSpacing : 0)
		}
		contentHeight = cachedSectionHeight.reduce(into: collectionView.adjustedContentInset.top) { $0 += $1.value }
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
	{
		var attributesArray: [UICollectionViewLayoutAttributes] = []

		attributesArray = cachedAttributes.filter { $0.frame.intersects(rect) }
		/*
		 // Find any cell that sits within the query rect - Binary search here for optimum performance
		 guard
		 let firstMatchIndex = binarySearch(cachedAttributes, searchFor: { rect.intersects($0.frame) }, shouldSearchEarlier: { $0.frame.minY >= rect.maxY })
		 else { return attributesArray }

		 // Starting from the match, loop up and down through the array until all the attributes
		 // have been added within the query rect.
		 var beforeSearch = 0
		 for attributes in cachedAttributes[..<firstMatchIndex].reversed() {
		 if attributes.frame.maxY >= rect.minY {
		 attributesArray.append(attributes)
		 } else {
		 //Check the previous few items, as in the waterfall layout they may be within the rect despite this one not being
		 beforeSearch += 1
		 if beforeSearch > numberOfColumns { break }
		 }
		 }

		 var afterSearch = 0
		 for attributes in cachedAttributes[firstMatchIndex...] {
		 if attributes.frame.minY <= rect.maxY {
		 attributesArray.append(attributes)
		 } else {
		 //Check the next few items, as in the waterfall layout they may be within the rect despite this one not being
		 afterSearch += 1
		 if afterSearch > numberOfColumns { break }
		 }
		 }
		 */
		return attributesArray
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	{
		cachedAttributes[indexPath]
	}

	public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	{
		switch elementKind
		{
		case UICollectionView.elementKindSectionHeader:
			return cachedAttributes[IndexPath(item: -1, section: indexPath.section)]
		default:
			return nil
		}
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
	{
		if newBounds.width != collectionView?.bounds.width
		{
			return true
		}
		return false
	}

	public override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool
	{
		guard !hasDelegate else { return false }
		if originalAttributes.indexPath.item == -1
		{
			guard
				let height = cachedHeaderHeight[originalAttributes.indexPath.section],
				height == preferredAttributes.size.height
			else { return true }
		}
		else
		{
			guard
				let height = cachedHeight[originalAttributes.indexPath],
				height == preferredAttributes.size.height
			else { return true } // Either no cached height, or has changed...
		}

		return false
	}

	public override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext
	{
		let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
		guard let collectionView = collectionView else { return context }

		guard preferredAttributes.frame.height != originalAttributes.frame.height else
		{
			return context
		}
		if originalAttributes.indexPath.item == -1
		{
			cachedHeaderHeight[originalAttributes.indexPath.section] = preferredAttributes.size.height
		}
		else
		{
			cachedHeight[originalAttributes.indexPath] = preferredAttributes.size.height
		}

		// If an item has changed size, the layout of everything underneath it has also been invalidated.
		context.invalidateItems(at: collectionView.allIndexPaths(after: originalAttributes.indexPath))

		return context
	}
}

// MARK: Delegate

@available(iOS 13.0, *)
public protocol ASWaterfallLayoutDelegate
{
	func heightForHeader(sectionIndex: Int) -> CGFloat?
	func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat
}

// MARK: Helpers

/*
 public func binarySearch<T: Collection>(_ sequence: T, searchFor: ((T.Element) -> Bool), shouldSearchEarlier: ((T.Element) -> Bool)) -> Int? where T.Index == Int {
 var lowerBound = 0
 var upperBound = sequence.count
 while lowerBound < upperBound {
 	let midIndex = lowerBound + (upperBound - lowerBound) / 2
 	if searchFor(sequence[midIndex]) {
 		return midIndex
 	} else if shouldSearchEarlier(sequence[midIndex]) {
 		lowerBound = midIndex + 1
 	} else {
 		upperBound = midIndex
 	}
 }
 return nil
 }*/

extension Array where Element: Comparable
{
	public func indexOfMin() -> Int?
	{
		// swiftformat:disable redundantSelf
		self.min().flatMap(firstIndex(of:))
		// swiftformat:enable redundantSelf
	}
}
