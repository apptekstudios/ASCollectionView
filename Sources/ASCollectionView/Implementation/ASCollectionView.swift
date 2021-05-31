// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

@available(iOS 13.0, *)
public struct ASCollectionView<SectionID: Hashable>: UIViewControllerRepresentable, ContentSize
{
	// MARK: Type definitions

	public typealias Section = ASCollectionViewSection<SectionID>
	public typealias Layout = ASCollectionLayout<SectionID>

	public typealias OnScrollCallback = ((_ contentOffset: CGPoint, _ contentSize: CGSize) -> Void)
	public typealias OnReachedBoundaryCallback = ((_ boundary: Boundary) -> Void)

	// MARK: Key variables

	public var layout: Layout = .default
	public var sections: [Section]
	public var editMode: Bool = false

	// MARK: Internal variables modified by modifier functions

	internal var delegateInitialiser: (() -> ASCollectionViewDelegate) = ASCollectionViewDelegate.init

	internal var contentSizeTracker: ContentSizeTracker?

	internal var onScrollCallback: OnScrollCallback?
	internal var onReachedBoundaryCallback: OnReachedBoundaryCallback?

	internal var backgroundColor: UIColor?

	internal var horizontalScrollIndicatorEnabled: Bool = true
	internal var verticalScrollIndicatorEnabled: Bool = true
	internal var contentInsets: UIEdgeInsets = .zero

	internal var onPullToRefresh: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?
    
    internal var onWillDisplay: ((UICollectionViewCell, IndexPath) -> Void)?
    
    internal var onDidDisplay: ((UICollectionViewCell, IndexPath) -> Void)?

	internal var alwaysBounceVertical: Bool = false
	internal var alwaysBounceHorizontal: Bool = false

	internal var scrollPositionSetter: Binding<ASCollectionViewScrollPosition?>?

	internal var animateOnDataRefresh: Bool = true

	internal var maintainScrollPositionOnOrientationChange: Bool = true

	internal var shouldInvalidateLayoutOnStateChange: Bool = false
	internal var shouldAnimateInvalidatedLayoutOnStateChange: Bool = false

	internal var shouldRecreateLayoutOnStateChange: Bool = false
	internal var shouldAnimateRecreatedLayoutOnStateChange: Bool = false

	internal var dodgeKeyboard: Bool = true

	// MARK: Environment variables

	// SwiftUI environment
	@Environment(\.invalidateCellLayout) var invalidateParentCellLayout // Call this if using content size binding (nested inside another ASCollectionView)

	public func makeUIViewController(context: Context) -> AS_CollectionViewController
	{
		context.coordinator.parent = self

		let delegate = delegateInitialiser()
		delegate.coordinator = context.coordinator

		let collectionViewLayout = layout.makeLayout(withCoordinator: context.coordinator)

		let collectionViewController = AS_CollectionViewController(collectionViewLayout: collectionViewLayout)
		collectionViewController.coordinator = context.coordinator

		context.coordinator.collectionViewController = collectionViewController
		context.coordinator.delegate = delegate

		context.coordinator.setupDataSource(forCollectionView: collectionViewController.collectionView)

		return collectionViewController
	}

	public func updateUIViewController(_ collectionViewController: AS_CollectionViewController, context: Context)
	{
		context.coordinator.parent = self
		context.coordinator.updateCollectionViewSettings(collectionViewController.collectionView)
		context.coordinator.updateContent(collectionViewController.collectionView, transaction: context.transaction)
		context.coordinator.updateLayout()
		context.coordinator.configureRefreshControl(for: collectionViewController.collectionView)
		context.coordinator.setupKeyboardObservers()
#if DEBUG
		debugOnly_checkHasUniqueSections()
#endif
	}

	public func makeCoordinator() -> Coordinator
	{
		Coordinator(self)
	}

#if DEBUG
	func debugOnly_checkHasUniqueSections()
	{
		var sectionIDs: Set<SectionID> = []
		var conflicts: Set<SectionID> = []
		sections.forEach
		{
			let (inserted, _) = sectionIDs.insert($0.id)
			if !inserted
			{
				conflicts.insert($0.id)
			}
		}
		if !conflicts.isEmpty
		{
			print("ASCOLLECTIONVIEW: The following section IDs are used more than once, please use unique section IDs to avoid unexpected behaviour:", conflicts)
		}
	}
#endif

	// MARK: Coordinator Class

	public class Coordinator: ASCollectionViewCoordinator
	{
		var parent: ASCollectionView
		var delegate: ASCollectionViewDelegate?

		weak var collectionViewController: AS_CollectionViewController?

		var dataSource: ASDiffableDataSourceCollectionView<SectionID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString

		// MARK: Private tracking variables

		private var hasDoneInitialSetup = false
		private var shouldAnimateScrollPositionSet = false

		private var hasFiredBoundaryNotificationForBoundary: Set<Boundary> = []
		private var haveRegisteredForSupplementaryOfKind: Set<String> = []

		private var selectedIndexPaths: Set<IndexPath> = []

		typealias Cell = ASCollectionViewCell

		init(_ parent: ASCollectionView)
		{
			self.parent = parent
		}

		deinit
		{
			NotificationCenter.default.removeObserver(self)
		}

		func sectionID(fromSectionIndex sectionIndex: Int) -> SectionID?
		{
			parent.sections[safe: sectionIndex]?.id
		}

		func section(forItemID itemID: ASCollectionViewItemUniqueID) -> Section?
		{
			parent.sections
				.first(where: { $0.id.hashValue == itemID.sectionIDHash })
		}

		func supplementaryKinds() -> Set<String>
		{
			parent.sections.reduce(into: Set<String>())
			{ result, section in
				result.formUnion(section.supplementaryKinds)
			}
		}

		func registerSupplementaries(forCollectionView cv: UICollectionView)
		{
			supplementaryKinds().subtracting(haveRegisteredForSupplementaryOfKind).forEach
			{ kind in
				cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryReuseID)
				self.haveRegisteredForSupplementaryOfKind.insert(kind) // We don't need to register this kind again now.
			}
		}

		func updateCollectionViewSettings(_ collectionView: UICollectionView)
		{
			assignIfChanged(collectionView, \.backgroundColor, newValue: parent.backgroundColor)
			assignIfChanged(collectionView, \.dragInteractionEnabled, newValue: true)
			assignIfChanged(collectionView, \.alwaysBounceVertical, newValue: parent.alwaysBounceVertical)
			assignIfChanged(collectionView, \.alwaysBounceHorizontal, newValue: parent.alwaysBounceHorizontal)
			assignIfChanged(collectionView, \.allowsSelection, newValue: true)
			assignIfChanged(collectionView, \.allowsMultipleSelection, newValue: true)
			assignIfChanged(collectionView, \.showsVerticalScrollIndicator, newValue: parent.verticalScrollIndicatorEnabled)
			assignIfChanged(collectionView, \.showsHorizontalScrollIndicator, newValue: parent.horizontalScrollIndicatorEnabled)
			assignIfChanged(collectionView, \.keyboardDismissMode, newValue: .interactive)
			updateCollectionViewContentInsets(collectionView)
		}

		func updateCollectionViewContentInsets(_ collectionView: UICollectionView)
		{
			assignIfChanged(collectionView, \.contentInsetAdjustmentBehavior, newValue: delegate?.collectionViewContentInsetAdjustmentBehavior ?? .automatic)
			assignIfChanged(collectionView, \.contentInset, newValue: adaptiveContentInsets)
		}

		func isIndexPathSelected(_ indexPath: IndexPath) -> Bool
		{
			collectionViewController?.collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
		}

		func setupDataSource(forCollectionView cv: UICollectionView)
		{
			cv.delegate = delegate
			cv.dragDelegate = delegate
			cv.dropDelegate = delegate

			cv.register(Cell.self, forCellWithReuseIdentifier: cellReuseID)

			dataSource = .init(collectionView: cv)
			{ [weak self] collectionView, indexPath, itemID in
				guard let self = self else { return nil }

				guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseID, for: indexPath) as? Cell
				else { return nil }

				guard let section = self.parent.sections[safe: indexPath.section] else { return cell }

				cell.collectionViewController = self.collectionViewController

				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .content, indexPath: indexPath)
				cell.selfSizingConfig =
					section.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? self.delegate?.collectionViewSelfSizingSettings(forContext: selfSizingContext)
						?? (collectionView.collectionViewLayout as? ASCollectionViewLayoutProtocol)?.selfSizingConfig
						?? ASSelfSizingConfig()

				cell.isSelected = self.isIndexPathSelected(indexPath)

				cell.setContent(itemID: itemID, content: section.dataSource.content(forItemID: itemID))

				cell.disableSwiftUIDropInteraction = section.dataSource.dropEnabled
				cell.disableSwiftUIDragInteraction = section.dataSource.dragEnabled

				cell.hostingController.invalidateCellLayoutCallback = { [weak self] animated in
					self?.invalidateLayoutOnNextUpdate = true // Queue for after updated data passed to ASCollectionView
					self?.invalidateLayout(animated: animated) // Do immediately in-case the change is in state within the cell
				}
				cell.hostingController.collectionViewScrollToCellCallback = { [weak self] position in
					self?.scrollToItem(indexPath: indexPath, position: position)
				}

				return cell
			}
			dataSource?.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
				guard let self = self else { return nil }

				guard self.supplementaryKinds().contains(kind)
				else
				{
					return nil
				}
				guard let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
				else { return nil }

				guard let section = self.parent.sections[safe: indexPath.section] else { reusableView.setAsEmpty(supplementaryID: nil); return reusableView }
				let supplementaryID = ASSupplementaryCellID(sectionIDHash: section.id.hashValue, supplementaryKind: kind)
				reusableView.supplementaryID = supplementaryID

				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .supplementary(kind), indexPath: indexPath)
				reusableView.selfSizingConfig =
					section.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? ASSelfSizingConfig()

				reusableView.setContent(supplementaryID: supplementaryID, content: section.dataSource.content(supplementaryID: supplementaryID))

				return reusableView
			}
			setupPrefetching()
		}

		func populateDataSource(animated: Bool = true, transaction: Transaction? = nil)
		{
			guard hasDoneInitialSetup else { return }
			collectionViewController.map { registerSupplementaries(forCollectionView: $0.collectionView) } // New sections might involve new types of supplementary...
			let snapshot = ASDiffableDataSourceSnapshot(sections:
				parent.sections.map
				{
					ASDiffableDataSourceSnapshot.Section(id: $0.id, elements: $0.itemIDs)
				}
			)
			if invalidateLayoutOnNextUpdate
			{
				collectionViewController?.collectionViewLayout.invalidateLayout()
				invalidateLayoutOnNextUpdate = false
			}
			dataSource?.applySnapshot(snapshot, animated: animated)
			shouldAnimateScrollPositionSet = animated

			refreshVisibleCells(transaction: transaction, updateAll: false)
		}

		func updateContent(_ cv: UICollectionView, transaction: Transaction?)
		{
			guard hasDoneInitialSetup else { return }

			let transactionAnimationEnabled = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			populateDataSource(
				animated: parent.animateOnDataRefresh && transactionAnimationEnabled,
				transaction: transaction)

			updateSelection(cv, transaction: transaction)
		}

		func refreshVisibleCells(transaction: Transaction? = nil, updateAll: Bool = true)
		{
			guard let cv = collectionViewController?.collectionView else { return }
			for cell in cv.visibleCells
			{
				refreshCell(cell, forceUpdate: updateAll)
			}

			supplementaryKinds().forEach
			{ kind in
				for indexPath in cv.indexPathsForVisibleSupplementaryElements(ofKind: kind)
				{
					guard let supplementaryView = (cv.supplementaryView(forElementKind: kind, at: indexPath) as? ASCollectionViewSupplementaryView) else { continue }
					guard let section = parent.sections[safe: indexPath.section] else { continue }

					// Get cachedHC
					let supplementaryID = ASSupplementaryCellID(sectionIDHash: section.id.hashValue, supplementaryKind: kind)
					// Update hostingController
					supplementaryView.setContent(supplementaryID: supplementaryID, content: section.dataSource.content(supplementaryID: supplementaryID))
				}
			}
		}

		func refreshCell(_ cell: UICollectionViewCell, forceUpdate: Bool = false)
		{
			guard
				let cell = cell as? Cell,
				let itemID = cell.itemID,
				let section = section(forItemID: itemID)
			else { return }
//			if cell.skipNextRefresh, !forceUpdate
//			{
//				cell.skipNextRefresh = false
//			}
//			else
//			{
			cell.setContent(itemID: itemID, content: section.dataSource.content(forItemID: itemID))
			cell.disableSwiftUIDropInteraction = section.dataSource.dropEnabled
			cell.disableSwiftUIDragInteraction = section.dataSource.dragEnabled
//			}
		}

		func onMoveToParent()
		{
			guard !hasDoneInitialSetup else { return }

			hasDoneInitialSetup = true
			populateDataSource(animated: false)
		}

		func onMoveFromParent() {}

		var invalidateLayoutOnNextUpdate: Bool = false
		func invalidateLayout(animated: Bool)
		{
			CATransaction.begin()
			if !animated
			{
				CATransaction.setDisableActions(true)
			}
			collectionViewController?.collectionViewLayout.invalidateLayout()
			CATransaction.commit()
		}

		var areKeyboardObserversSetUp: Bool = false
		func setupKeyboardObservers()
		{
			if parent.dodgeKeyboard
			{
				guard !areKeyboardObserversSetUp else { return }
				areKeyboardObserversSetUp = true
				NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
				NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
			}
			else if areKeyboardObserversSetUp
			{
				NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
				NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
			}
		}

		var keyboardFrame: CGRect?
		{
			didSet
			{
				collectionViewController.map
				{
					updateCollectionViewContentInsets($0.collectionView)
				}
			}
		}

		var keyboardOverlap: CGFloat
		{
			guard
				let cv = collectionViewController?.collectionView,
				let cvFrameInWindow = cv.superview?.convert(cv.frame, to: nil),
				let intersection = keyboardFrame?.intersection(cvFrameInWindow)
			else { return .zero }
			return intersection.height
		}

		var extraKeyboardSpacing: CGFloat = 25

		var adaptiveContentInsets: UIEdgeInsets
		{
			UIEdgeInsets(
				top: parent.contentInsets.top,
				left: parent.contentInsets.left,
				bottom: parent.contentInsets.bottom + (parent.dodgeKeyboard ? keyboardOverlap : 0),
				right: parent.contentInsets.right)
		}

		func containsFirstResponder() -> Bool
		{
			collectionViewController?.collectionView.findFirstResponder != nil
		}

		@objc func keyBoardWillShow(notification: Notification)
		{
			guard containsFirstResponder()
			else
			{
				keyboardFrame = nil
				return
			}

			keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

			// Do our own adjustment of contentOffset
			if let cv = collectionViewController?.collectionView,
				let firstResponder = cv.findFirstResponder()
			{
				let firstResponderFrame = firstResponder.convert(firstResponder.bounds, to: cv)
				let newContentOffset = CGPoint(
					x: cv.contentOffset.x,
					y: cv.adjustedContentInset.top + firstResponderFrame.maxY + keyboardOverlap + extraKeyboardSpacing - cv.frame.height)
				if newContentOffset.y > cv.contentOffset.y
				{
					cv.contentOffset = newContentOffset
				}
			}
		}

		@objc func keyBoardWillHide(notification _: Notification)
		{
			keyboardFrame = nil
			collectionViewController?.collectionView.layoutIfNeeded()
		}

		func configureRefreshControl(for cv: UICollectionView)
		{
			guard parent.onPullToRefresh != nil
			else
			{
				if cv.refreshControl != nil
				{
					cv.refreshControl = nil
				}
				return
			}
			if cv.refreshControl == nil
			{
				let refreshControl = UIRefreshControl()
				refreshControl.addTarget(self, action: #selector(collectionViewDidPullToRefresh), for: .valueChanged)
				cv.refreshControl = refreshControl
			}
		}

		@objc
		public func collectionViewDidPullToRefresh()
		{
			guard let collectionView = collectionViewController?.collectionView else { return }
			let endRefreshing: (() -> Void) = { [weak collectionView] in
				collectionView?.refreshControl?.endRefreshing()
			}
			parent.onPullToRefresh?(endRefreshing)
		}

		// MARK: Functions for determining scroll position (on appear, and also on orientation change)

		func scrollToItem(indexPath: IndexPath, position: UICollectionView.ScrollPosition = [])
		{
			CATransaction.begin()
			collectionViewController?.collectionView.scrollToItem(at: indexPath, at: position, animated: true)
			CATransaction.commit()
		}

		func applyScrollPosition(animated: Bool)
		{
			if let scrollPositionToSet = parent.scrollPositionSetter?.wrappedValue
			{
				scrollToPosition(scrollPositionToSet, animated: animated)
				DispatchQueue.main.async
				{
					self.parent.scrollPositionSetter?.wrappedValue = nil
				}
			}
		}

		func scrollToPosition(_ scrollPosition: ASCollectionViewScrollPosition, animated: Bool = false)
		{
			switch scrollPosition
			{
			case .top, .left:
				collectionViewController?.collectionView.setContentOffset(.zero, animated: animated)
			case .bottom:
				guard let maxOffset = collectionViewController?.collectionView.maxContentOffset else { return }
				collectionViewController?.collectionView.setContentOffset(.init(x: 0, y: maxOffset.y), animated: animated)
			case .right:
				guard let maxOffset = collectionViewController?.collectionView.maxContentOffset else { return }
				collectionViewController?.collectionView.setContentOffset(.init(x: maxOffset.x, y: 0), animated: animated)
			case let .indexPath(indexPath, positionOnScreen, extraOffset):
				collectionViewController?.collectionView.scrollToItem(at: indexPath, at: positionOnScreen, animated: animated)
				collectionViewController?.collectionView.contentOffset.x += extraOffset.x
				collectionViewController?.collectionView.contentOffset.y += extraOffset.y
			}
		}

		func prepareForOrientationChange()
		{
			guard let collectionView = collectionViewController?.collectionView else { return }

			if parent.maintainScrollPositionOnOrientationChange
			{
				// Get centremost cell
				if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY))
				{
					// Item at centre
					transitionCentralIndexPath = indexPath
				}
				else if let visibleCells = collectionViewController?.collectionView.indexPathsForVisibleItems, !visibleCells.isEmpty
				{
					// Approximate item at centre
					transitionCentralIndexPath = visibleCells[visibleCells.count / 2]
				}
				else
				{
					transitionCentralIndexPath = nil
				}
			}
		}

		var transitionCentralIndexPath: IndexPath?
		func getContentOffsetForOrientationChange() -> CGPoint?
		{
			if parent.maintainScrollPositionOnOrientationChange
			{
				guard let currentOffset = collectionViewController?.collectionView.contentOffset, currentOffset.x > 0, currentOffset.y > 0 else { return nil }
				return transitionCentralIndexPath.flatMap(getContentOffsetToCenterCell)
			}
			else
			{
				return nil
			}
		}

		func completedOrientationChange()
		{
			transitionCentralIndexPath = nil
		}

		func getContentOffsetToCenterCell(at indexPath: IndexPath) -> CGPoint?
		{
			guard
				let collectionView = collectionViewController?.collectionView,
				let centerCellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame
			else { return nil }
			let maxOffset = collectionView.maxContentOffset
			let newOffset = CGPoint(
				x: max(0, min(maxOffset.x, centerCellFrame.midX - (collectionView.bounds.width / 2))),
				y: max(0, min(maxOffset.y, centerCellFrame.midY - (collectionView.bounds.height / 2))))
			return newOffset
		}

		// MARK: Functions for updating layout

		func updateLayout()
		{
			guard
				hasDoneInitialSetup,
				let collectionViewController = collectionViewController else { return }
			// Configure any custom layout
			parent.layout.configureLayout(layoutObject: collectionViewController.collectionView.collectionViewLayout)

			// If enabled, recreate the layout
			if parent.shouldRecreateLayoutOnStateChange
			{
				let newLayout = parent.layout.makeLayout(withCoordinator: self)
				collectionViewController.collectionView.setCollectionViewLayout(newLayout, animated: parent.shouldAnimateRecreatedLayoutOnStateChange && hasDoneInitialSetup)
			}
			// If enabled, invalidate the layout
			else if parent.shouldInvalidateLayoutOnStateChange
			{
				let changes = {
					collectionViewController.collectionViewLayout.invalidateLayout()
				}
				if parent.shouldAnimateInvalidatedLayoutOnStateChange, hasDoneInitialSetup
				{
					changes()
				}
				else
				{
					CATransaction.begin()
					CATransaction.setDisableActions(true)
					changes()
					CATransaction.commit()
				}
			}
		}

		// MARK: CollectionViewDelegate functions

		// NOTE: These are not called directly, but rather forwarded to the Coordinator by the ASCollectionViewDelegate class

		public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			currentlyPrefetching.remove(indexPath)
			parent.sections[safe: indexPath.section]?.dataSource.onAppear(indexPath)
			queuePrefetch.send()
            parent.onWillDisplay?(cell, indexPath)
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			guard !indexPath.isEmpty else { return }
			parent.sections[safe: indexPath.section]?.dataSource.onDisappear(indexPath)
            parent.onDidDisplay?(cell, indexPath)
		}

		public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
		{}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
		{}

		public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldHighlight(indexPath) ?? true
		}

		public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
		{
			parent.sections[safe: indexPath.section]?.dataSource.highlightIndex(indexPath.item)
		}

		public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
		{
			parent.sections[safe: indexPath.section]?.dataSource.unhighlightIndex(indexPath.item)
		}

		public func collectionView(_ collectionView: UICollectionView, willSelectItemAt indexPath: IndexPath) -> IndexPath?
		{
			self.collectionView(collectionView, shouldSelectItemAt: indexPath) ? indexPath : nil
		}

		public func collectionView(_ collectionView: UICollectionView, willDeselectItemAt indexPath: IndexPath) -> IndexPath?
		{
			self.collectionView(collectionView, shouldDeselectItemAt: indexPath) ? indexPath : nil
		}

		public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldSelect(indexPath) ?? true
		}

		public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldDeselect(indexPath) ?? true
		}

		public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
		{
			updateSelection(collectionView)
			parent.sections[safe: indexPath.section]?.dataSource.didSelect(indexPath)
		}

		public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
		{
			updateSelection(collectionView)
		}

		func updateSelection(_ collectionView: UICollectionView, transaction: Transaction? = nil)
		{
			let selectedInDataSource = selectedIndexPathsInDataSource
			let selectedInCollectionView = Set(collectionView.indexPathsForSelectedItems ?? [])
			guard selectedInDataSource != selectedInCollectionView else { return }

			let newSelection = threeWayMerge(base: selectedIndexPaths, dataSource: selectedInDataSource, collectionView: selectedInCollectionView)
			let (toDeselect, toSelect) = selectionDifferences(oldSelectedIndexPaths: selectedInCollectionView, newSelectedIndexPaths: newSelection)

			selectedIndexPaths = newSelection
			updateSelectionBindings(newSelection)
			updateSelectionInCollectionView(collectionView, indexPathsToDeselect: toDeselect, indexPathsToSelect: toSelect, transaction: transaction)
		}

		private var selectedIndexPathsInDataSource: Set<IndexPath>
		{
			parent.sections.enumerated().reduce(Set<IndexPath>())
			{ (selectedIndexPaths, section) -> Set<IndexPath> in
				guard let indexes = section.element.dataSource.selectedIndicesBinding?.wrappedValue else { return selectedIndexPaths }
				let indexPaths = indexes.map { IndexPath(item: $0, section: section.offset) }
				return selectedIndexPaths.union(indexPaths)
			}
		}

		private func threeWayMerge(base: Set<IndexPath>, dataSource: Set<IndexPath>, collectionView: Set<IndexPath>) -> Set<IndexPath>
		{
			// In case the data source and collection view are both different from base, default to the collection view
			base == collectionView ? dataSource : collectionView
		}

		private func selectionDifferences(oldSelectedIndexPaths: Set<IndexPath>, newSelectedIndexPaths: Set<IndexPath>) -> (toDeselect: Set<IndexPath>, toSelect: Set<IndexPath>)
		{
			let toDeselect = oldSelectedIndexPaths.subtracting(newSelectedIndexPaths)
			let toSelect = newSelectedIndexPaths.subtracting(oldSelectedIndexPaths)
			return (toDeselect: toDeselect, toSelect: toSelect)
		}

		private func updateSelectionBindings(_ selectedIndexPaths: Set<IndexPath>)
		{
			let selectionBySection = Dictionary(grouping: selectedIndexPaths) { $0.section }
				.mapValues
				{
					Set($0.map(\.item))
				}
			parent.sections.enumerated().forEach
			{ offset, section in
				section.dataSource.updateSelection(with: selectionBySection[offset] ?? [])
			}
		}

		private func updateSelectionInCollectionView(_ collectionView: UICollectionView, indexPathsToDeselect: Set<IndexPath>, indexPathsToSelect: Set<IndexPath>, transaction: Transaction? = nil)
		{
			let isAnimated = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			indexPathsToDeselect.forEach { collectionView.deselectItem(at: $0, animated: isAnimated) }
			indexPathsToSelect.forEach { collectionView.selectItem(at: $0, animated: isAnimated, scrollPosition: []) }
		}

		func canDrop(at indexPath: IndexPath) -> Bool
		{
			guard !indexPath.isEmpty else { return false }

			return (parent.sections[safe: indexPath.section]?.dataSource.dropEnabled ?? false)
				&& (parent.sections[safe: indexPath.section]?.dataSource.canDropItem?(indexPath) ?? true)
		}

		func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
		{
			guard !indexPath.isEmpty else { return [] }
			guard let dragItem = parent.sections[safe: indexPath.section]?.dataSource.getDragItem(for: indexPath) else { return [] }
			return [dragItem]
		}

		func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal
		{
			if collectionView.hasActiveDrag
			{
				if let destination = destinationIndexPath
				{
					guard canDrop(at: destination)
					else
					{
						return UICollectionViewDropProposal(operation: .cancel)
					}
				}
				return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
			}
			else
			{
				return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
			}
		}

		func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator)
		{
			guard
				let destinationIndexPath = coordinator.destinationIndexPath,
				!destinationIndexPath.isEmpty,
				let destinationSection = parent.sections[safe: destinationIndexPath.section]
			else { return }

			guard canDrop(at: destinationIndexPath) else { return }

			guard let oldSnapshot = dataSource?.currentSnapshot else { return }
			var dragSnapshot = oldSnapshot

			switch coordinator.proposal.operation
			{
			case .move:
				guard destinationSection.dataSource.reorderingEnabled else { return }

				let itemsBySourceSection = Dictionary(grouping: coordinator.items)
				{ item -> Int? in
					if let sourceIndex = item.sourceIndexPath, !sourceIndex.isEmpty,
						destinationSection.dataSource.supportsMove(from: sourceIndex, to: destinationIndexPath)
					{
						return sourceIndex.section
					}
					else
					{
						return nil
					}
				}

				let sourceSections = itemsBySourceSection.keys.sorted
				{ a, b in
					guard let a = a else { return false }
					guard let b = b else { return true }
					return a < b
				}

				var itemsToInsert: [UICollectionViewDropItem] = []

				for sourceSectionIndex in sourceSections
				{
					guard let items = itemsBySourceSection[sourceSectionIndex] else { continue }

					if
						let sourceSectionIndex = sourceSectionIndex,
						let sourceSection = parent.sections[safe: sourceSectionIndex]
					{
						guard sourceSection.dataSource.reorderingEnabled else { continue }

						let sourceIndices = items.compactMap { $0.sourceIndexPath?.item }

						// Remove from source section
						dragSnapshot.removeItems(fromSectionIndex: sourceSectionIndex, atOffsets: IndexSet(sourceIndices))
						sourceSection.dataSource.applyRemove(atOffsets: IndexSet(sourceIndices))
					}

					// Add to insertion array (regardless whether sourceSection is nil)
					itemsToInsert.append(contentsOf: items)
				}

				let itemsToInsertIDs: [ASCollectionViewItemUniqueID] = itemsToInsert.compactMap
				{ item in
					if let sourceIndexPath = item.sourceIndexPath
					{
						return oldSnapshot.sections[sourceIndexPath.section].elements[sourceIndexPath.item].differenceIdentifier
					}
					else
					{
						return destinationSection.dataSource.getItemID(for: item.dragItem, withSectionID: destinationSection.id)
					}
				}
				if destinationSection.dataSource.applyInsert(items: itemsToInsert.map(\.dragItem), at: destinationIndexPath.item)
				{
					dragSnapshot.insertItems(itemsToInsertIDs, atSectionIndex: destinationIndexPath.section, atOffset: destinationIndexPath.item)
				}

			case .copy:
				_ = destinationSection.dataSource.applyInsert(items: coordinator.items.map(\.dragItem), at: destinationIndexPath.item)

			default: break
			}

			if let dragItem = coordinator.items.first, let destination = coordinator.destinationIndexPath
			{
				if dragItem.sourceIndexPath != nil
				{
					coordinator.drop(dragItem.dragItem, toItemAt: destination)
				}
			}
			dataSource?.applySnapshot(dragSnapshot, animated: true)
			refreshVisibleCells()
		}

		func typeErasedDataForItem(at indexPath: IndexPath) -> Any?
		{
			guard !indexPath.isEmpty else { return nil }
			return parent.sections[safe: indexPath.section]?.dataSource.getTypeErasedData(for: indexPath)
		}

		// MARK: Functions for updating contentSize binding

		var lastContentSize: CGSize = .zero
		func didUpdateContentSize(_ size: CGSize)
		{
			guard let cv = collectionViewController?.collectionView, cv.contentSize.width != .zero, cv.contentSize.height != .zero else { return }

			if cv.contentSize != lastContentSize
			{
				let firstSize = lastContentSize == .zero
				lastContentSize = cv.contentSize
				parent.contentSizeTracker?.contentSize = size

				DispatchQueue.main.async
				{
					self.parent.invalidateParentCellLayout?(!firstSize)
				}
				applyScrollPosition(animated: shouldAnimateScrollPositionSet)
			}
		}

		// MARK: Variables used for the custom prefetching implementation

		private let queuePrefetch = PassthroughSubject<Void, Never>()
		private var prefetchSubscription: AnyCancellable?
		private var currentlyPrefetching: Set<IndexPath> = []
	}
}

// MARK: OnScroll/OnReachedBoundary support

@available(iOS 13.0, *)
extension ASCollectionView.Coordinator
{
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		parent.onScrollCallback?(scrollView.contentOffset, scrollView.contentSizePlusInsets)
		checkIfReachedBoundary(scrollView)
	}

	func checkIfReachedBoundary(_ scrollView: UIScrollView)
	{
		let scrollableHorizontally = scrollView.contentSizePlusInsets.width > scrollView.frame.size.width
		let scrollableVertically = scrollView.contentSizePlusInsets.height > scrollView.frame.size.height

		for boundary in Boundary.allCases
		{
			let hasReachedBoundary: Bool = {
				switch boundary
				{
				case .left:
					return scrollableHorizontally && scrollView.contentOffset.x <= 0
				case .top:
					return scrollableVertically && scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top
				case .right:
					return scrollableHorizontally && (scrollView.contentSizePlusInsets.width - scrollView.contentOffset.x) <= scrollView.frame.size.width
				case .bottom:
					return scrollableVertically && (scrollView.contentSizePlusInsets.height - scrollView.contentOffset.y) <= scrollView.frame.size.height
				}
			}()

			if hasReachedBoundary
			{
				// If we haven't already fired the notification, send it now
				if !hasFiredBoundaryNotificationForBoundary.contains(boundary)
				{
					hasFiredBoundaryNotificationForBoundary.insert(boundary)
					parent.onReachedBoundaryCallback?(boundary)
				}
			}
			else
			{
				// No longer at this boundary, reset so it can fire again if needed
				hasFiredBoundaryNotificationForBoundary.remove(boundary)
			}
		}
	}
}

// MARK: Context Menu Support

@available(iOS 13.0, *)
public extension ASCollectionView.Coordinator
{
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
	{
		guard !indexPath.isEmpty else { return nil }
		return parent.sections[safe: indexPath.section]?.dataSource.getContextMenu(for: indexPath)
	}
}

// MARK: Coordinator Protocol

@available(iOS 13.0, *)
internal protocol ASCollectionViewCoordinator: AnyObject
{
	func typeErasedDataForItem(at indexPath: IndexPath) -> Any?
	func prepareForOrientationChange()
	func getContentOffsetForOrientationChange() -> CGPoint?
	func completedOrientationChange()
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
	func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
	func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator)
	func didUpdateContentSize(_ size: CGSize)
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	func onMoveToParent()
	func onMoveFromParent()
}

// MARK: Custom Prefetching Implementation

@available(iOS 13.0, *)
extension ASCollectionView.Coordinator
{
	func setupPrefetching()
	{
		let numberToPreload = 5
		prefetchSubscription = queuePrefetch
			.collect(.byTime(DispatchQueue.main, 0.1)) // .throttle CRASHES on 13.1, fixed from 13.3 but still using .collect for 13.1 compatibility
			.compactMap
			{ [weak collectionViewController] _ in
				collectionViewController?.collectionView.indexPathsForVisibleItems
			}
			.receive(on: DispatchQueue.global(qos: .background))
			.map
			{ [weak self] visibleIndexPaths -> [Int: [IndexPath]] in
				guard let self = self else { return [:] }
				let visibleIndexPathsBySection = Dictionary(grouping: visibleIndexPaths) { $0.section }.compactMapValues
				{ (indexPaths) -> (section: Int, first: Int, last: Int)? in
					guard let first = indexPaths.min(), let last = indexPaths.max() else { return nil }
					return (section: first.section, first: first.item, last: last.item)
				}
				var toPrefetch: [Int: [IndexPath]] = visibleIndexPathsBySection.compactMapValues
				{ item in
					guard let sectionIndexPaths = self.parent.sections[safe: item.section]?.dataSource.getIndexPaths(withSectionIndex: item.section) else { return nil }
					let nextItemsInSection: ArraySlice<IndexPath> = {
						guard (item.last + 1) < sectionIndexPaths.endIndex else { return [] }
						return sectionIndexPaths[(item.last + 1) ..< min(item.last + numberToPreload + 1, sectionIndexPaths.endIndex)]
					}()
					let previousItemsInSection: ArraySlice<IndexPath> = {
						guard (item.first - 1) >= sectionIndexPaths.startIndex else { return [] }
						return sectionIndexPaths[max(sectionIndexPaths.startIndex, item.first - numberToPreload) ..< item.first]
					}()
					return Array(nextItemsInSection) + Array(previousItemsInSection)
				}
				// CHECK IF THERES AN EARLIER SECTION TO PRELOAD
				if
					let firstSection = toPrefetch.keys.min(), // FIND THE EARLIEST VISIBLE SECTION
					(firstSection - 1) >= self.parent.sections.startIndex, // CHECK THERE IS A SECTION BEFORE THIS
					let firstIndex = visibleIndexPathsBySection[firstSection]?.first, firstIndex < numberToPreload // CHECK HOW CLOSE TO THIS SECTION WE ARE
				{
					let precedingSection = firstSection - 1
					toPrefetch[precedingSection] = self.parent.sections[precedingSection].dataSource.getIndexPaths(withSectionIndex: precedingSection).suffix(numberToPreload)
				}
				// CHECK IF THERES A LATER SECTION TO PRELOAD
				if
					let lastSection = toPrefetch.keys.max(), // FIND THE LAST VISIBLE SECTION
					(lastSection + 1) < self.parent.sections.endIndex, // CHECK THERE IS A SECTION AFTER THIS
					let lastIndex = visibleIndexPathsBySection[lastSection]?.last,
					let lastSectionEndIndex = self.parent.sections[lastSection].dataSource.getIndexPaths(withSectionIndex: lastSection).last?.item,
					(lastSectionEndIndex - lastIndex) < numberToPreload // CHECK HOW CLOSE TO THIS SECTION WE ARE
				{
					let nextSection = lastSection + 1
					toPrefetch[nextSection] = Array(self.parent.sections[nextSection].dataSource.getIndexPaths(withSectionIndex: nextSection).prefix(numberToPreload))
				}
				return toPrefetch
			}
			.sink
			{ [weak self] prefetch in
				prefetch.forEach
				{ sectionIndex, toPrefetch in
					if !toPrefetch.isEmpty
					{
						self?.parent.sections[safe: sectionIndex]?.dataSource.prefetch(toPrefetch)
					}
					if
						let toCancel = self?.currentlyPrefetching.filter({ $0.section == sectionIndex }).subtracting(toPrefetch),
						!toCancel.isEmpty
					{
						self?.parent.sections[safe: sectionIndex]?.dataSource.cancelPrefetch(Array(toCancel))
					}
				}

				self?.currentlyPrefetching = Set(prefetch.flatMap(\.value))
			}
	}
}

@available(iOS 13.0, *)
public enum ASCollectionViewScrollPosition
{
	case top
	case bottom
	case left
	case right
	case indexPath(_: IndexPath, positionOnScreen: UICollectionView.ScrollPosition = .centeredVertically, extraOffset: CGPoint = .zero)
}
