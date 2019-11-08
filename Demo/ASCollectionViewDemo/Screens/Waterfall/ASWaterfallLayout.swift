//
//  ASWaterfallLayout.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 8/11/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import UIKit
import ASCollectionView

class ASWaterfallLayout: UICollectionViewLayout, ASCollectionViewLayoutProtocol {
	var estimatedItemHeight: CGFloat = 400
	
	struct CellLayoutContext {
		var width: CGFloat
	}
	
	var numberOfColumns: Int = 3 {
		didSet {
			invalidateLayout()
		}
	}
	
	var columnSpacing: CGFloat = 6 {
		didSet {
			invalidateLayout()
		}
	}
	
	var sectionSpacing: CGFloat = 20 {
		didSet {
			invalidateLayout()
		}
	}
	
	var itemSpacing: CGFloat = 6 {
		didSet {
			invalidateLayout()
		}
	}
	
	let selfSizeVertically = true
	let selfSizeHorizontally = false
	
	
	private var cachedHeight: [IndexPath: CGFloat] = [:]
	private var cachedSectionHeight: [Int: CGFloat] = [:]
	
	private var cachedAttributes: OrderedDictionary<IndexPath, UICollectionViewLayoutAttributes> = .init()
	
	private var contentHeight: CGFloat = 0
	
	private var contentWidth: CGFloat {
		guard let collectionView = collectionView else { return 0 }
		let insets = collectionView.adjustedContentInset
		return collectionView.bounds.width - (insets.left + insets.right) - 0.0001
	}
	
	override var collectionViewContentSize: CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	
	var columnWidth: CGFloat {
		(contentWidth - (columnSpacing * CGFloat(numberOfColumns - 1))) / CGFloat(numberOfColumns)
	}
	
	var hasDelegate: Bool {
		collectionView?.delegate is ASCollectionViewDelegate
	}
	func getHeight(for indexPath: IndexPath) -> CGFloat {
		if let delegate = (collectionView?.delegate as? ASWaterfallLayoutDelegate) {
			return delegate.heightForCell(at: indexPath,
										  context: ASWaterfallLayout.CellLayoutContext(width: columnWidth))
		}
		return cachedHeight[indexPath] ?? estimatedItemHeight
	}
	
	override func prepare() {
		guard let collectionView = collectionView else { return }
		
		// Reset cached information.
		cachedAttributes.removeAll()
		
		guard let sections = collectionView.allSections else { return }
		for section in sections {
			let sectionMinY = (0..<section).reduce(into: collectionView.adjustedContentInset.top) { $0 += cachedSectionHeight[$1] ?? 0 }
			var columnHeights: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
			
			for indexPath in collectionView.allIndexPaths(inSection: section) {
				let targetColumn = columnHeights.indexOfMin() ?? 0
				
				let minY = columnHeights[targetColumn]
				let sizeY = getHeight(for: indexPath)
				let maxY = minY + sizeY + itemSpacing
				
				let minX = (columnWidth + columnSpacing) * CGFloat(targetColumn)
				let sizeX = columnWidth
				
				//Set cached attributes
				let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
				attributes.frame = CGRect(x: minX,
										  y: sectionMinY + minY,
										  width: sizeX,
										  height: sizeY)
				cachedAttributes.append((indexPath, attributes))
				
				//Update height of column
				columnHeights[targetColumn] = maxY
			}
			cachedSectionHeight[section] = (columnHeights.max() ?? 0) + (section != (sections.count - 1) ? sectionSpacing : 0)
		}
		contentHeight = cachedSectionHeight.reduce(into: collectionView.adjustedContentInset.top, { $0 += $1.value })
	}
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
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
	
	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return cachedAttributes[indexPath]
	}
	
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		if newBounds.width != collectionView?.bounds.width {
			return true
		}
		return false
	}
	
	override public func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
		guard !hasDelegate else { return false }
		guard
			let height = self.cachedHeight[originalAttributes.indexPath],
			height == preferredAttributes.size.height
			else { return true } //Either no cached height, or has changed...
		return false
	}
	
	override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
		let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
		guard let collectionView = collectionView else { return context }
		
		guard preferredAttributes.frame.height != originalAttributes.frame.height else {
			return context
		}
		self.cachedHeight[originalAttributes.indexPath] = preferredAttributes.size.height

		// If an item has changed size, the layout of everything underneath it has also been invalidated.
		context.invalidateItems(at: collectionView.allIndexPaths(after: originalAttributes.indexPath))
		
		return context
	}
}

extension UICollectionView {
	var allSections: Range<Int>? {
		let sectionCount = dataSource?.numberOfSections?(in: self) ?? 1
		guard sectionCount > 0 else { return nil }
		return (0 ..< sectionCount)
	}
	
	func allIndexPaths(inSection section: Int) -> [IndexPath] {
		guard let itemCount = dataSource?.collectionView(self, numberOfItemsInSection: section), itemCount > 0 else { return [] }
		return (0..<itemCount).map { item in
			return IndexPath(item: item, section: section)
		}
	}
	
	func allIndexPaths() -> [IndexPath] {
		guard let allSections = allSections else { return [] }
		return allSections.flatMap { section -> [IndexPath] in
			allIndexPaths(inSection: section)
		}
	}
	func allIndexPaths(after afterIndexPath: IndexPath) -> [IndexPath] {
		guard let sectionCount = dataSource?.numberOfSections?(in: self), sectionCount > 0 else { return [] }
		return (afterIndexPath.section ..< sectionCount).flatMap { section -> [IndexPath] in
			guard let itemCount = dataSource?.collectionView(self, numberOfItemsInSection: section), itemCount > 0 else { return [] }
			let startIndex: Int
			if section == afterIndexPath.section {
				startIndex = afterIndexPath.item + 1
			} else {
				startIndex = 0
			}
			guard startIndex < itemCount else { return [] }
			return (startIndex..<itemCount).map { item in
				return IndexPath(item: item, section: section)
			}
		}
	}
}

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
}

extension Array where Element: Comparable {
	public func indexOfMin() -> Int? {
		self.min().flatMap(firstIndex(of:))
	}
}

struct OrderedDictionary<Key: Hashable, Value>: BidirectionalCollection {
	private var dictionary: [Key: Int] = [:]
	private var array: [Value] = []
	
	
	mutating func append(_ item: (key: Key, value: Value)) {
		if let index = dictionary[item.key] {
			array.remove(at: index)
		}
		array.append(item.value)
		dictionary[item.key] = array.endIndex - 1
	}
	
	mutating func append(_ items: [(key: Key, value: Value)]) {
		items.forEach { append($0) }
	}
	
	mutating func removeAll() {
		dictionary.removeAll()
		array.removeAll()
	}
	
	var startIndex: Int { array.startIndex }
	
	var endIndex: Int { array.endIndex }
	
	var lastIndex: Int { Swift.max(startIndex, endIndex - 1) }
	
	func index(before i: Int) -> Int {
		array.index(before: i)
	}
	
	func index(after i: Int) -> Int {
		array.index(after: i)
	}
	
	subscript(index: Int) -> Value {
		array[index]
	}
	
	subscript(_ key: Key) -> Value? {
		get {
			dictionary[key].map { array[$0] }
		}
		set {
			guard let newValue = newValue else {
				_ = dictionary[key].map { array.remove(at: $0) }
				return
			}
			if let index = dictionary[key] {
				array[index] = newValue
			} else {
				append((key, value: newValue))
			}
		}
	}
}
