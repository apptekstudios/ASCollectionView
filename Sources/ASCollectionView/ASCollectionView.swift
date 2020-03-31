// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

// MARK: Init for single-section CV

@available(iOS 13.0, *)
extension ASCollectionView where SectionID == Int
{
	/**
	 Initializes a  collection view with a single section.

	 - Parameters:
	 	- section: A single section (ASCollectionViewSection)
	 */
	public init(section: Section)
	{
		sections = [section]
	}

	/**
	 Initializes a  collection view with a single section of static content
	 */
	public init(@ViewArrayBuilder staticContent: () -> ViewArrayBuilder.Wrapper)
	{
		self.init(sections: [ASCollectionViewSection(id: 0, content: staticContent)])
	}

	/**
	 Initializes a  collection view with a single section.
	 */
	public init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View>(
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, CellContext) -> Content))
		where DataCollection.Index == Int
	{
		let section = ASCollectionViewSection(
			id: 0,
			data: data,
			dataID: dataIDKeyPath,
			contentBuilder: contentBuilder)
		sections = [section]
	}

	/**
	 Initializes a  collection view with a single section with identifiable data
	 */
	public init<DataCollection: RandomAccessCollection, Content: View>(
		data: DataCollection,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, CellContext) -> Content))
		where DataCollection.Index == Int, DataCollection.Element: Identifiable
	{
		self.init(data: data, dataID: \.id, contentBuilder: contentBuilder)
	}
}

@available(iOS 13.0, *)
public struct ASCollectionView<SectionID: Hashable>: UIViewControllerRepresentable, ContentSize
{
	// MARK: Type definitions

	public typealias Section = ASCollectionViewSection<SectionID>
	public typealias Layout = ASCollectionLayout<SectionID>

	// MARK: Key variables

	public var layout: Layout = .default
	public var sections: [Section]

	// MARK: Internal variables modified by modifier functions

	var delegateInitialiser: (() -> ASCollectionViewDelegate) = ASCollectionViewDelegate.init

	var contentSizeTracker: ContentSizeTracker?

	var shouldInvalidateLayoutOnStateChange: Bool = false
	var shouldAnimateInvalidatedLayoutOnStateChange: Bool = false

	var shouldRecreateLayoutOnStateChange: Bool = false
	var shouldAnimateRecreatedLayoutOnStateChange: Bool = false

	// MARK: Environment variables

	// SwiftUI environment
	@Environment(\.editMode) private var editMode

	// ASCollectionView environment
	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled
	@Environment(\.contentInsets) private var contentInsets
	@Environment(\.alwaysBounceHorizontal) private var alwaysBounceHorizontal
	@Environment(\.alwaysBounceVertical) private var alwaysBounceVertical
	@Environment(\.initialScrollPosition) private var initialScrollPosition
	@Environment(\.onPullToRefresh) private var onPullToRefresh
	@Environment(\.collectionViewOnReachedBoundary) private var onReachedBoundary
	@Environment(\.animateOnDataRefresh) private var animateOnDataRefresh
	@Environment(\.attemptToMaintainScrollPositionOnOrientationChange) private var attemptToMaintainScrollPositionOnOrientationChange
	@Environment(\.allowCellWidthToExceedCollectionContentSize) private var allowCellWidthToExceedCollectionContentSize
	@Environment(\.allowCellHeightToExceedCollectionContentSize) private var allowCellHeightToExceedCollectionContentSize

	// MARK: Init for multi-section CVs

	/**
	 Initializes a  collection view with the given sections

	 - Parameters:
	 	- sections: An array of sections (ASCollectionViewSection)
	 */
	@inlinable public init(sections: [Section])
	{
		self.sections = sections
	}

	@inlinable public init(@SectionArrayBuilder <SectionID> sectionBuilder: () -> [Section])
	{
		sections = sectionBuilder()
	}

	public func makeUIViewController(context: Context) -> AS_CollectionViewController
	{
		context.coordinator.parent = self

		let delegate = delegateInitialiser()
		context.coordinator.delegate = delegate
		delegate.coordinator = context.coordinator

		let collectionViewLayout = layout.makeLayout(withCoordinator: context.coordinator)

		let collectionViewController = AS_CollectionViewController(collectionViewLayout: collectionViewLayout)
		collectionViewController.coordinator = context.coordinator
		updateCollectionViewSettings(collectionViewController.collectionView, delegate: delegate)

		context.coordinator.collectionViewController = collectionViewController

		context.coordinator.setupDataSource(forCollectionView: collectionViewController.collectionView)
		return collectionViewController
	}

	public func updateUIViewController(_ collectionViewController: AS_CollectionViewController, context: Context)
	{
		context.coordinator.parent = self
		updateCollectionViewSettings(collectionViewController.collectionView, delegate: context.coordinator.delegate)
		context.coordinator.updateLayout()
		context.coordinator.updateContent(collectionViewController.collectionView, transaction: context.transaction, refreshExistingCells: true)
		context.coordinator.configureRefreshControl(for: collectionViewController.collectionView)
	}

	func updateCollectionViewSettings(_ collectionView: UICollectionView, delegate: ASCollectionViewDelegate?)
	{
		assignIfChanged(collectionView, \.dragInteractionEnabled, newValue: true)
		assignIfChanged(collectionView, \.contentInsetAdjustmentBehavior, newValue: delegate?.collectionViewContentInsetAdjustmentBehavior ?? .automatic)
		assignIfChanged(collectionView, \.contentInset, newValue: contentInsets)
		assignIfChanged(collectionView, \.alwaysBounceVertical, newValue: alwaysBounceVertical)
		assignIfChanged(collectionView, \.alwaysBounceHorizontal, newValue: alwaysBounceHorizontal)
		assignIfChanged(collectionView, \.showsVerticalScrollIndicator, newValue: scrollIndicatorsEnabled)
		assignIfChanged(collectionView, \.showsHorizontalScrollIndicator, newValue: scrollIndicatorsEnabled)

		let isEditing = editMode?.wrappedValue.isEditing ?? false
		assignIfChanged(collectionView, \.allowsSelection, newValue: isEditing)
		assignIfChanged(collectionView, \.allowsMultipleSelection, newValue: isEditing)
	}

	public func makeCoordinator() -> Coordinator
	{
		Coordinator(self)
	}

	// MARK: Coordinator Class

	public class Coordinator: ASCollectionViewCoordinator
	{
		var parent: ASCollectionView
		var delegate: ASCollectionViewDelegate?

		weak var collectionViewController: AS_CollectionViewController?

		var dataSource: ASCollectionViewDiffableDataSource<SectionID, ASCollectionViewItemUniqueID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString
		let supplementaryEmptyKind = UUID().uuidString // Used to prevent crash if supplementaries defined in layout but not provided by the section

		// MARK: Private tracking variables

		private var hasDoneInitialSetup = false
		private var hasFiredBoundaryNotificationForBoundary: Set<Boundary> = []

		private var haveRegisteredForSupplementaryOfKind: Set<String> = []

		// MARK: Caching

		private var visibleHostingControllers: [ASCollectionViewItemUniqueID: ASHostingControllerProtocol] = [:]
		private var autoCachingHostingControllers = ASPriorityCache<ASCollectionViewItemUniqueID, ASHostingControllerProtocol>()

		private var cachedHostingControllers: [ASCollectionViewItemUniqueID: ASHostingControllerProtocol] = [:]

		typealias Cell = ASCollectionViewCell

		init(_ parent: ASCollectionView)
		{
			self.parent = parent
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
			let emptyKindSet: Set<String> = [supplementaryEmptyKind] // Used to prevent crash if supplementaries defined in layout but not provided by the section
			return parent.sections.reduce(into: emptyKindSet) { result, section in
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

		func setupDataSource(forCollectionView cv: UICollectionView)
		{
			cv.delegate = delegate
			cv.dragDelegate = delegate
			cv.dropDelegate = delegate

			cv.register(Cell.self, forCellWithReuseIdentifier: cellReuseID)
			registerSupplementaries(forCollectionView: cv)

			dataSource = .init(collectionView: cv)
			{ [weak self] (collectionView, indexPath, itemID) -> UICollectionViewCell? in
				guard let self = self else { return nil }

				guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseID, for: indexPath) as? Cell
				else { return nil }

				guard let section = self.parent.sections[safe: indexPath.section] else { return cell }

				cell.invalidateLayout = { [weak collectionView] in
					collectionView?.collectionViewLayout.invalidateLayout()
				}
				cell.maxSizeForSelfSizing = ASOptionalSize(
					width: self.parent.allowCellWidthToExceedCollectionContentSize ? nil : collectionView.contentSize.width,
					height: self.parent.allowCellHeightToExceedCollectionContentSize ? nil : collectionView.contentSize.height)

				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .content, indexPath: indexPath)
				cell.selfSizingConfig =
					section.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? self.delegate?.collectionViewSelfSizingSettings(forContext: selfSizingContext)
						?? (collectionView.collectionViewLayout as? ASCollectionViewLayoutProtocol)?.selfSizingConfig
						?? ASSelfSizingConfig(selfSizeHorizontally: true, selfSizeVertically: true)

				// Update hostingController
				let cachedHC = self.cachedHostingControllers[itemID] ?? self.visibleHostingControllers[itemID] ?? self.autoCachingHostingControllers[itemID]
				cell.hostingController = section.dataSource.updateOrCreateHostController(forItemID: itemID, existingHC: cachedHC)

				// Cache the HC
				self.autoCachingHostingControllers[itemID] = cell.hostingController
				self.visibleHostingControllers[itemID] = cell.hostingController
				if section.shouldCacheCells
				{
					self.cachedHostingControllers[itemID] = cell.hostingController
				}

				return cell
			}
			dataSource?.supplementaryViewProvider = { [weak self] (cv, kind, indexPath) -> UICollectionReusableView? in
				guard let self = self else { return nil }

				guard self.supplementaryKinds().contains(kind) else
				{
					let emptyView = cv.dequeueReusableSupplementaryView(ofKind: self.supplementaryEmptyKind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
					emptyView?.setupAsEmptyView()
					return emptyView
				}
				guard let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
				else { return nil }

				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .supplementary(kind), indexPath: indexPath)
				reusableView.selfSizingConfig =
					self.parent.sections[safe: indexPath.section]?.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? self.delegate?.collectionViewSelfSizingSettings(forContext: selfSizingContext)
						?? ASSelfSizingConfig(selfSizeHorizontally: true, selfSizeVertically: true)

				if let supplementaryView = self.parent.sections[safe: indexPath.section]?.supplementary(ofKind: kind)
				{
					reusableView.setupFor(
						id: indexPath.section,
						view: supplementaryView)
				}
				else
				{
					reusableView.setupAsEmptyView()
				}

				return reusableView
			}
			setupPrefetching()
		}

		func populateDataSource(animated: Bool = true, isInitialLoad: Bool = false)
		{
			var snapshot = NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>()
			snapshot.appendSections(parent.sections.map { $0.id })
			parent.sections.forEach
			{
				snapshot.appendItems($0.itemIDs, toSection: $0.id)
			}
			dataSource?.apply(snapshot, animatingDifferences: animated, isInitialLoad: isInitialLoad)
			{
				self.collectionViewController.map { self.didUpdateContentSize($0.collectionView.contentSize) }
			}
		}

		func updateContent(_ cv: UICollectionView, transaction: Transaction?, refreshExistingCells: Bool)
		{
			guard hasDoneInitialSetup else { return }
			registerSupplementaries(forCollectionView: cv) // New sections might involve new types of supplementary...
			if refreshExistingCells
			{
				withAnimation(parent.animateOnDataRefresh ? transaction?.animation : nil) {
					visibleHostingControllers.forEach { itemID, hc in
						section(forItemID: itemID)?.dataSource.update(hc, forItemID: itemID)
					}
				}

				supplementaryKinds().forEach
				{ kind in
					cv.indexPathsForVisibleSupplementaryElements(ofKind: kind).forEach
					{
						guard let supplementaryView = parent.sections[safe: $0.section]?.supplementary(ofKind: kind) else { return }
						(cv.supplementaryView(forElementKind: kind, at: $0) as? ASCollectionViewSupplementaryView)?
							.updateView(supplementaryView)
					}
				}
			}
			let transactionAnimationEnabled = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			populateDataSource(animated: parent.animateOnDataRefresh && transactionAnimationEnabled)
			updateSelectionBindings(cv)
		}

		func onMoveToParent()
		{
			if !hasDoneInitialSetup
			{
				hasDoneInitialSetup = true

				// Populate data source
				populateDataSource(animated: false, isInitialLoad: true)

				// Set initial scroll position
				parent.initialScrollPosition.map { scrollToPosition($0, animated: false) }
			}
		}

		func onMoveFromParent()
		{}

		func configureRefreshControl(for cv: UICollectionView)
		{
			guard parent.onPullToRefresh != nil else
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
			case let .centerOnIndexPath(indexPath):
				guard let offset = getContentOffsetToCenterCell(at: indexPath) else { return }
				collectionViewController?.collectionView.setContentOffset(offset, animated: animated)
			}
		}

		func prepareForOrientationChange()
		{
			guard let collectionView = collectionViewController?.collectionView else { return }

			if parent.attemptToMaintainScrollPositionOnOrientationChange
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
			if parent.attemptToMaintainScrollPositionOnOrientationChange
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
			guard let collectionViewController = collectionViewController else { return }
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
					collectionViewController.collectionView.layoutIfNeeded()
				}
				if parent.shouldAnimateInvalidatedLayoutOnStateChange, hasDoneInitialSetup
				{
					UIView.animate(
						withDuration: 0.4,
						delay: 0.0,
						usingSpringWithDamping: 1.0,
						initialSpringVelocity: 0.0,
						options: UIView.AnimationOptions(),
						animations: changes,
						completion: nil)
				}
				else
				{
					changes()
				}
			}
		}

		// MARK: CollectionViewDelegate functions

		// NOTE: These are not called directly, but rather forwarded to the Coordinator by the ASCollectionViewDelegate class

		public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			collectionViewController.map { (cell as? Cell)?.willAppear(in: $0) }
			currentlyPrefetching.remove(indexPath)
			guard !indexPath.isEmpty else { return }
			parent.sections[safe: indexPath.section]?.dataSource.onAppear(indexPath)
			queuePrefetch.send()
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			guard !indexPath.isEmpty else { return }
			parent.sections[safe: indexPath.section]?.dataSource.onDisappear(indexPath)
			(cell as? Cell)?.itemID.map { visibleHostingControllers[$0] = nil }
		}

		public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
		{
			(view as? ASCollectionViewSupplementaryView)?.willAppear(in: collectionViewController)
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
		{
			(view as? ASCollectionViewSupplementaryView)?.didDisappear()
		}

		public func collectionView(_ collectionView: UICollectionView, willSelectItemAt indexPath: IndexPath) -> IndexPath?
		{
			guard parent.sections[safe: indexPath.section]?.dataSource.shouldSelect(indexPath) ?? true else
			{
				return nil
			}
			return indexPath
		}

		public func collectionView(_ collectionView: UICollectionView, willDeselectItemAt indexPath: IndexPath) -> IndexPath?
		{
			guard parent.sections[safe: indexPath.section]?.dataSource.shouldDeselect(indexPath) ?? true else
			{
				return nil
			}
			return indexPath
		}

		public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
		{
			updateContent(collectionView, transaction: nil, refreshExistingCells: true)
		}

		public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
		{
			updateContent(collectionView, transaction: nil, refreshExistingCells: true)
		}

		func updateSelectionBindings(_ collectionView: UICollectionView)
		{
			let selected = collectionView.indexPathsForSelectedItems ?? []
			let selectedSafe = selected.filter { parent.sections.containsIndex($0.section) }
			let selectionBySection = Dictionary(grouping: selectedSafe) { $0.section }
				.mapValues
			{
				Set($0.map { $0.item })
			}
			parent.sections.enumerated().forEach { offset, section in
				section.dataSource.updateSelection(selectionBySection[offset] ?? [])
			}
		}

		func dragItem(for indexPath: IndexPath) -> UIDragItem?
		{
			guard !indexPath.isEmpty else { return nil }
			return parent.sections[safe: indexPath.section]?.dataSource.getDragItem(for: indexPath)
		}

		func canDrop(at indexPath: IndexPath) -> Bool
		{
			guard !indexPath.isEmpty else { return false }
			return parent.sections[safe: indexPath.section]?.dataSource.dropEnabled ?? false
		}

		func removeItem(from indexPath: IndexPath)
		{
			guard !indexPath.isEmpty else { return }
			parent.sections[safe: indexPath.section]?.dataSource.removeItem(from: indexPath)
		}

		func insertItems(_ items: [UIDragItem], at indexPath: IndexPath)
		{
			guard !indexPath.isEmpty else { return }
			parent.sections[safe: indexPath.section]?.dataSource.insertDragItems(items, at: indexPath)
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
			guard let cv = collectionViewController?.collectionView, cv.contentSize != lastContentSize else { return }
			lastContentSize = cv.contentSize
			parent.contentSizeTracker?.contentSize = size
		}

		// MARK: Variables used for the custom prefetching implementation

		private let queuePrefetch = PassthroughSubject<Void, Never>()
		private var prefetchSubscription: AnyCancellable?
		private var currentlyPrefetching: Set<IndexPath> = []
	}
}

// MARK: OnReachedBoundary support

@available(iOS 13.0, *)
extension ASCollectionView.Coordinator
{
	public func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
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
					parent.onReachedBoundary(boundary)
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

// MARK: Modifer: Custom Delegate

@available(iOS 13.0, *)
public extension ASCollectionView
{
	/// Use this modifier to assign a custom delegate type (subclass of ASCollectionViewDelegate). This allows support for old UICollectionViewLayouts that require a delegate.
	func customDelegate(_ delegateInitialiser: @escaping (() -> ASCollectionViewDelegate)) -> Self
	{
		var cv = self
		cv.delegateInitialiser = delegateInitialiser
		return cv
	}
}

// MARK: Modifer: Layout Invalidation

@available(iOS 13.0, *)
public extension ASCollectionView
{
	/// For use in cases where you would like to change layout settings in response to a change in variables referenced by your layout closure.
	/// Note: this ensures the layout is invalidated
	/// - For UICollectionViewCompositionalLayout this means that your SectionLayout closure will be called again
	/// - closures capture value types when created, therefore you must refer to a reference type in your layout closure if you want it to update.
	func shouldInvalidateLayoutOnStateChange(_ shouldInvalidate: Bool, animated: Bool = true) -> Self
	{
		var this = self
		this.shouldInvalidateLayoutOnStateChange = shouldInvalidate
		this.shouldAnimateInvalidatedLayoutOnStateChange = animated
		return this
	}

	/// For use in cases where you would like to recreate the layout object in response to a change in state. Eg. for changing layout types completely
	/// If not changing the type of layout (eg. to a different class) t is preferable to invalidate the layout and update variables in the `configureCustomLayout` closure
	func shouldRecreateLayoutOnStateChange(_ shouldRecreate: Bool, animated: Bool = true) -> Self
	{
		var this = self
		this.shouldRecreateLayoutOnStateChange = shouldRecreate
		this.shouldAnimateRecreatedLayoutOnStateChange = animated
		return this
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
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
	func dragItem(for indexPath: IndexPath) -> UIDragItem?
	func canDrop(at indexPath: IndexPath) -> Bool
	func removeItem(from indexPath: IndexPath)
	func insertItems(_ items: [UIDragItem], at indexPath: IndexPath)
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
		let numberToPreload = 8
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
			guard let self = self else { return }
			prefetch.forEach
			{ sectionIndex, toPrefetch in
				if !toPrefetch.isEmpty
				{
					self.parent.sections[safe: sectionIndex]?.dataSource.prefetch(toPrefetch)
				}
				let toCancel = self.currentlyPrefetching.filter { $0.section == sectionIndex }.subtracting(toPrefetch)
				if !toCancel.isEmpty
				{
					self.parent.sections[safe: sectionIndex]?.dataSource.cancelPrefetch(Array(toCancel))
				}
			}

			self.currentlyPrefetching = Set(prefetch.flatMap { $0.value })
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
	case centerOnIndexPath(_: IndexPath)
}

@available(iOS 13.0, *)
public class AS_CollectionViewController: UIViewController
{
	weak var coordinator: ASCollectionViewCoordinator?
	{
		didSet
		{
			guard viewIfLoaded != nil else { return }
			collectionView.coordinator = coordinator
		}
	}

	var collectionViewLayout: UICollectionViewLayout
	lazy var collectionView: AS_UICollectionView = {
		let cv = AS_UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
		cv.coordinator = coordinator
		return cv
	}()

	public init(collectionViewLayout layout: UICollectionViewLayout)
	{
		collectionViewLayout = layout
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	public override func didMove(toParent parent: UIViewController?)
	{
		super.didMove(toParent: parent)
		if parent != nil
		{
			coordinator?.onMoveToParent()
		}
		else
		{
			coordinator?.onMoveFromParent()
		}
	}

	public override func loadView()
	{
		view = collectionView
	}

	public override func viewDidLoad()
	{
		super.viewDidLoad()
		view.backgroundColor = .clear
	}

	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
	{
		// Get current central cell
		self.coordinator?.prepareForOrientationChange()

		super.viewWillTransition(to: size, with: coordinator)
		// The following is a workaround to fix the interface rotation animation under SwiftUI
		view.frame = CGRect(origin: view.frame.origin, size: size)

		coordinator.animate(alongsideTransition: { _ in
			self.view.setNeedsLayout()
			self.view.layoutIfNeeded()
			if
				let desiredOffset = self.coordinator?.getContentOffsetForOrientationChange(),
				self.collectionView.contentOffset != desiredOffset
			{
				self.collectionView.contentOffset = desiredOffset
			}
		})
		{ _ in
			// Completion
			self.coordinator?.completedOrientationChange()
		}
	}

	public override func viewSafeAreaInsetsDidChange()
	{
		super.viewSafeAreaInsetsDidChange()
		// The following is a workaround to fix the interface rotation animation under SwiftUI
		collectionViewLayout.invalidateLayout()
	}

	public override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		coordinator?.didUpdateContentSize(collectionView.contentSize)
	}
}

@available(iOS 13.0, *)
class AS_UICollectionView: UICollectionView
{
	weak var coordinator: ASCollectionViewCoordinator?

	public override func didMoveToWindow()
	{
		super.didMoveToWindow()
		guard window != nil else { return }
		// Intended as a temporary workaround for a SwiftUI bug present in 13.3 -> the UIViewController is not moved to a parent when embedded in a list/scrollview
		coordinator?.onMoveToParent()
	}
}

// MARK: PUBLIC layout modifier functions

@available(iOS 13.0, *)
public extension ASCollectionView
{
	func layout(_ layout: Layout) -> Self
	{
		var this = self
		this.layout = layout
		return this
	}

	func layout(
		scrollDirection: UICollectionView.ScrollDirection = .vertical,
		interSectionSpacing: CGFloat = 10,
		layoutPerSection: @escaping CompositionalLayout<SectionID>) -> Self
	{
		var this = self
		this.layout = Layout(
			scrollDirection: scrollDirection,
			interSectionSpacing: interSectionSpacing,
			layoutPerSection: layoutPerSection)
		return this
	}

	func layout(
		scrollDirection: UICollectionView.ScrollDirection = .vertical,
		interSectionSpacing: CGFloat = 10,
		layout: @escaping CompositionalLayoutIgnoringSections) -> Self
	{
		var this = self
		this.layout = Layout(
			scrollDirection: scrollDirection,
			interSectionSpacing: interSectionSpacing,
			layout: layout)
		return this
	}

	func layout(customLayout: @escaping (() -> UICollectionViewLayout)) -> Self
	{
		var this = self
		this.layout = Layout(customLayout: customLayout)
		return this
	}

	func layout<LayoutClass: UICollectionViewLayout>(createCustomLayout: @escaping (() -> LayoutClass), configureCustomLayout: @escaping ((LayoutClass) -> Void)) -> Self
	{
		var this = self
		this.layout = Layout(createCustomLayout: createCustomLayout, configureCustomLayout: configureCustomLayout)
		return this
	}
}

@available(iOS 13.0, *)
class ASCollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable
{
	// private let updateQueue = DispatchQueue(label: "ASCollectionViewUpdateQueue", qos: .userInitiated)

	func apply(_ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, isInitialLoad: Bool = false, completion: (() -> Void)? = nil)
	{
		if animatingDifferences
		{
			super.apply(snapshot, animatingDifferences: true, completion: completion)
		}
		else
		{
			UIView.performWithoutAnimation {
				super.apply(snapshot, animatingDifferences: !isInitialLoad, completion: completion) // Animation must be true to get diffing. However we have disabled animation using .performWithoutAnimation
			}
		}
	}
}
