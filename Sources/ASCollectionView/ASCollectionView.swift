// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

// MARK: Init for single-section CV

extension ASCollectionView where SectionID == Int
{
	/**
	 Initializes a  collection view with a single section.

	 - Parameters:
	 	- section: A single section (ASCollectionViewSection)
	 */
	public init(selectedItems: Binding<IndexSet>? = nil, section: Section)
	{
		sections = [section]
		self.selectedItems = selectedItems.map
		{ selectedItems in
			Binding(
				get: { [:] },
				set: { selectedItems.wrappedValue = $0.first?.value ?? [] })
		}
	}

	/**
	 Initializes a  collection view with a single section.
	 */
	public init<Data, DataID: Hashable, Content: View>(
		data: [Data],
		dataID dataIDKeyPath: KeyPath<Data, DataID>,
		selectedItems: Binding<IndexSet>? = nil,
		@ViewBuilder contentBuilder: @escaping ((Data, CellContext) -> Content))
	{
		let section = ASCollectionViewSection(
			id: 0,
			data: data,
			dataID: dataIDKeyPath,
			contentBuilder: contentBuilder)
		sections = [section]
		self.selectedItems = selectedItems.map
		{ selectedItems in
			Binding(
				get: { [:] },
				set: { selectedItems.wrappedValue = $0.first?.value ?? [] })
		}
	}

	/**
	 Initializes a  collection view with a single section of static content
	 */
	init(@ViewArrayBuilder staticContent: () -> [AnyView]) // Clashing with above functions in Swift 5.1, therefore internal for time being
	{
		sections = [
			ASCollectionViewSection(id: 0, content: staticContent)
		]
	}
}

public struct ASCollectionView<SectionID: Hashable>: UIViewControllerRepresentable, ContentSize
{
	public typealias Section = ASCollectionViewSection<SectionID>
	public typealias Layout = ASCollectionLayout<SectionID>
	public var layout: Layout = .default
	public var sections: [Section]
	public var selectedItems: Binding<[SectionID: IndexSet]>?

	var contentSize: Binding<CGSize?>?

	var delegateInitialiser: (() -> ASCollectionViewDelegate) = ASCollectionViewDelegate.init

	var shouldInvalidateLayoutOnStateChange: Bool = false
	var shouldAnimateInvalidatedLayoutOnStateChange: Bool = false

	var shouldRecreateLayoutOnStateChange: Bool = false
	var shouldAnimateRecreatedLayoutOnStateChange: Bool = false

	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled
	@Environment(\.contentInsets) private var contentInsets
	@Environment(\.alwaysBounceHorizontal) private var alwaysBounceHorizontal
	@Environment(\.alwaysBounceVertical) private var alwaysBounceVertical
	@Environment(\.initialScrollPosition) private var initialScrollPosition
	@Environment(\.editMode) private var editMode

	// MARK: Init for multi-section CVs

	/**
	 Initializes a  collection view with the given sections

	 - Parameters:
	 	- sections: An array of sections (ASCollectionViewSection)
	 */
	@inlinable public init(selectedItems: Binding<[SectionID: IndexSet]>? = nil, sections: [Section])
	{
		self.selectedItems = selectedItems
		self.sections = sections
	}

	@inlinable public init(selectedItems: Binding<[SectionID: IndexSet]>? = nil, @SectionArrayBuilder <SectionID> sectionBuilder: () -> [Section])
	{
		self.selectedItems = selectedItems
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
		context.coordinator.updateContent(collectionViewController.collectionView, animated: true, refreshExistingCells: true)
	}

	func updateCollectionViewSettings(_ collectionView: UICollectionView, delegate: ASCollectionViewDelegate?)
	{
		collectionView.delegate = delegate
		collectionView.dragDelegate = delegate
		collectionView.dropDelegate = delegate
		collectionView.dragInteractionEnabled = true
		collectionView.contentInsetAdjustmentBehavior = delegate?.collectionViewContentInsetAdjustmentBehavior ?? .automatic
		collectionView.contentInset = contentInsets
		collectionView.alwaysBounceVertical = alwaysBounceVertical
		collectionView.alwaysBounceHorizontal = alwaysBounceHorizontal
		collectionView.showsVerticalScrollIndicator = scrollIndicatorsEnabled
		collectionView.showsHorizontalScrollIndicator = scrollIndicatorsEnabled

		let isEditing = editMode?.wrappedValue.isEditing ?? false
		collectionView.allowsSelection = isEditing
		collectionView.allowsMultipleSelection = isEditing
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

		var collectionViewController: AS_CollectionViewController?

		var dataSource: UICollectionViewDiffableDataSource<SectionID, ASCollectionViewItemUniqueID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString
		let supplementaryEmptyKind = UUID().uuidString // Used to prevent crash if supplementaries defined in layout but not provided by the section

		var hostingControllerCache = ASFIFODictionary<ASCollectionViewItemUniqueID, ASHostingControllerProtocol>()

		var hasSetInitialScrollPosition = false

		typealias Cell = ASCollectionViewCell

		init(_ parent: ASCollectionView)
		{
			self.parent = parent
		}

		func sectionID(fromSectionIndex sectionIndex: Int) -> SectionID
		{
			parent.sections[sectionIndex].id
		}

		func section(forItemID itemID: ASCollectionViewItemUniqueID) -> Section?
		{
			parent.sections
				.first(where: { $0.id.hashValue == itemID.sectionIDHash })
		}

		func supplementaryKinds() -> Set<String>
		{
			parent.sections.reduce(into: Set<String>()) { result, section in result.formUnion(section.supplementaryKinds) }
		}

		@discardableResult
		func configureHostingController(forItemID itemID: ASCollectionViewItemUniqueID, isSelected: Bool) -> ASHostingControllerProtocol?
		{
			let controller = section(forItemID: itemID)?.dataSource.configureHostingController(reusingController: hostingControllerCache[itemID], forItemID: itemID, isSelected: isSelected)
			hostingControllerCache[itemID] = controller
			return controller
		}

		func setupDataSource(forCollectionView cv: UICollectionView)
		{
			cv.register(Cell.self, forCellWithReuseIdentifier: cellReuseID)
			cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: supplementaryEmptyKind, withReuseIdentifier: supplementaryReuseID) // Used to prevent crash if supplementaries defined in layout but not provided by the section
			supplementaryKinds().forEach
			{ kind in
				cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryReuseID)
			}

			dataSource = .init(collectionView: cv)
			{ (collectionView, indexPath, itemID) -> UICollectionViewCell? in
				guard
					let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseID, for: indexPath) as? Cell
				else { return nil }
				let isSelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
				guard let hostController = self.configureHostingController(forItemID: itemID, isSelected: isSelected)
				else { return cell }
				cell.invalidateLayout = {
					collectionView.collectionViewLayout.invalidateLayout()
				}
				cell.selfSizeHorizontal =
					self.delegate?.collectionView(cellShouldSelfSizeHorizontallyForItemAt: indexPath)
					?? (collectionView.collectionViewLayout as? ASCollectionViewLayoutProtocol)?.selfSizeHorizontally
					?? true
				cell.selfSizeVertical =
					self.delegate?.collectionView(cellShouldSelfSizeVerticallyForItemAt: indexPath)
					?? (collectionView.collectionViewLayout as? ASCollectionViewLayoutProtocol)?.selfSizeVertically
					?? true
				cell.setupFor(
					id: itemID,
					hostingController: hostController)
				return cell
			}
			dataSource?.supplementaryViewProvider = { (cv, kind, indexPath) -> UICollectionReusableView? in
				guard self.supplementaryKinds().contains(kind) else
				{
					let emptyView = cv.dequeueReusableSupplementaryView(ofKind: self.supplementaryEmptyKind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
					return emptyView
				}
				guard let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
				else { return nil }
				if let supplementaryView = self.parent.sections[indexPath.section].supplementary(ofKind: kind)
				{
					reusableView.setupFor(
						id: indexPath.section,
						view: supplementaryView)
				}
				return reusableView
			}
			setupPrefetching()
		}

		func populateDataSource(animated: Bool = true)
		{
			var snapshot = NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>()
			snapshot.appendSections(parent.sections.map { $0.id })
			parent.sections.forEach
			{
				snapshot.appendItems($0.itemIDs, toSection: $0.id)
			}
			dataSource?.apply(snapshot, animatingDifferences: animated)
			{
				self.collectionViewController.map { self.didUpdateContentSize($0.collectionView.contentSize) }
			}
		}

		func updateContent(_ cv: UICollectionView, animated: Bool, refreshExistingCells: Bool)
		{
			if refreshExistingCells, collectionViewController?.parent != nil
			{
				cv.visibleCells.forEach
				{ cell in
					guard
						let cell = cell as? Cell,
						let itemID = cell.id
					else { return }

					self.configureHostingController(forItemID: itemID, isSelected: cell.isSelected)
				}

				supplementaryKinds().forEach
				{ kind in
					cv.indexPathsForVisibleSupplementaryElements(ofKind: kind).forEach
					{
						guard let supplementaryView = parent.sections[$0.section].supplementary(ofKind: kind) else { return }
						(cv.supplementaryView(forElementKind: kind, at: $0) as? ASCollectionViewSupplementaryView)?
							.updateView(supplementaryView)
					}
				}
			}
			populateDataSource(animated: collectionViewController?.parent != nil)
			updateSelectionBindings(cv)
			if !hasSetInitialScrollPosition
			{
				parent.initialScrollPosition.map { scrollToPosition($0, animated: false) }
				hasSetInitialScrollPosition = true
			}
		}

		func scrollToPosition(_ scrollPosition: ASCollectionViewScrollPosition, animated: Bool = false)
		{
			switch scrollPosition
			{
			case .top, .left:
				collectionViewController?.collectionView.setContentOffset(.zero, animated: animated)
			case .bottom:
				guard let contentSize = collectionViewController?.collectionView.contentSizePlusInsets else { return }
				collectionViewController?.collectionView.setContentOffset(.init(x: 0, y: contentSize.height), animated: animated)
			case .right:
				guard let contentSize = collectionViewController?.collectionView.contentSizePlusInsets else { return }
				collectionViewController?.collectionView.setContentOffset(.init(x: contentSize.width, y: 0), animated: animated)
			case let .centerOnIndexPath(indexPath):
				guard let offset = getContentOffsetToCenterCell(at: indexPath) else { return }
				collectionViewController?.collectionView.setContentOffset(offset, animated: animated)
			}
		}

		func prepareForOrientationChange()
		{
			guard let collectionView = collectionViewController?.collectionView else { return }
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

		var transitionCentralIndexPath: IndexPath?
		func getContentOffsetForOrientationChange() -> CGPoint?
		{
			transitionCentralIndexPath.flatMap(getContentOffsetToCenterCell)
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

		func updateLayout()
		{
			guard let collectionViewController = collectionViewController else { return }
			// Configure any custom layout
			parent.layout.configureLayout(layoutObject: collectionViewController.collectionView.collectionViewLayout)

			// If enabled, recreate the layout
			if parent.shouldRecreateLayoutOnStateChange
			{
				let newLayout = parent.layout.makeLayout(withCoordinator: self)
				collectionViewController.collectionView.setCollectionViewLayout(newLayout, animated: parent.shouldAnimateRecreatedLayoutOnStateChange && collectionViewController.parent != nil)
			}
			// If enabled, invalidate the layout
			else if parent.shouldInvalidateLayoutOnStateChange
			{
				let changes = {
					collectionViewController.collectionViewLayout.invalidateLayout()
					collectionViewController.collectionView.layoutIfNeeded()
				}
				if parent.shouldAnimateInvalidatedLayoutOnStateChange, collectionViewController.parent != nil
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

		public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.willAppear(in: collectionViewController)
			currentlyPrefetching.remove(indexPath)
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].dataSource.onAppear(indexPath)
			queuePrefetch.send()
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].dataSource.onDisappear(indexPath)
		}

		public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
		{
			(view as? ASCollectionViewSupplementaryView)?.willAppear(in: collectionViewController)
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
		{
			(view as? ASCollectionViewSupplementaryView)?.didDisappear()
		}

		public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
		{
			guard
				let cell = collectionView.cellForItem(at: indexPath) as? Cell,
				let itemID = cell.id
			else { return }
			updateSelectionBindings(collectionView)
			configureHostingController(forItemID: itemID, isSelected: true)
		}

		public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
		{
			guard
				let cell = collectionView.cellForItem(at: indexPath) as? Cell,
				let itemID = cell.id
			else { return }
			updateSelectionBindings(collectionView)
			configureHostingController(forItemID: itemID, isSelected: false)
		}

		func updateSelectionBindings(_ collectionView: UICollectionView)
		{
			guard let selectedItemsBinding = parent.selectedItems else { return }
			let selected = collectionView.indexPathsForSelectedItems ?? []
			let selectedSafe = selected.filter { $0.section < parent.sections.endIndex }
			let selectedBySection = Dictionary(grouping: selectedSafe)
			{
				parent.sections[$0.section].id
			}.mapValues
			{
				IndexSet($0.map { $0.item })
			}
			DispatchQueue.main.async
			{
				selectedItemsBinding.wrappedValue = selectedBySection
			}
		}

		func dragItem(for indexPath: IndexPath) -> UIDragItem?
		{
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return nil }
			return parent.sections[indexPath.section].dataSource.getDragItem(for: indexPath)
		}

		func canDrop(at indexPath: IndexPath) -> Bool
		{
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return false }
			return parent.sections[indexPath.section].dataSource.dropEnabled
		}

		func removeItem(from indexPath: IndexPath)
		{
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].dataSource.removeItem(from: indexPath)
		}

		func insertItems(_ items: [UIDragItem], at indexPath: IndexPath)
		{
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].dataSource.insertDragItems(items, at: indexPath)
		}

		func typeErasedDataForItem(at indexPath: IndexPath) -> Any?
		{
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return nil }
			return parent.sections[indexPath.section].dataSource.getTypeErasedData(for: indexPath)
		}

		var lastContentSize: CGSize = .zero
		func didUpdateContentSize(_ size: CGSize)
		{
			guard let cv = collectionViewController?.collectionView, cv.contentSize != lastContentSize else { return }
			lastContentSize = cv.contentSize
			if let contentSizeBinding = parent.contentSize, contentSizeBinding.wrappedValue != size
			{
				DispatchQueue.main.async
				{
					if contentSizeBinding.wrappedValue == nil
					{
						// Initial size setting, don't animate
						contentSizeBinding.wrappedValue = size
					}
					else
					{
						// Animate change
						contentSizeBinding.animation().wrappedValue = size
					}
				}
			}
		}

		private let queuePrefetch = PassthroughSubject<Void, Never>()
		private var prefetchSubscription: AnyCancellable?
		private var currentlyPrefetching: Set<IndexPath> = []
	}
}

// MARK: Modifer: Custom Delegate

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
	func dragItem(for indexPath: IndexPath) -> UIDragItem?
	func canDrop(at indexPath: IndexPath) -> Bool
	func removeItem(from indexPath: IndexPath)
	func insertItems(_ items: [UIDragItem], at indexPath: IndexPath)
	func didUpdateContentSize(_ size: CGSize)
}

// MARK: Custom Prefetching Implementation

extension ASCollectionView.Coordinator
{
	func setupPrefetching()
	{
		let numberToPreload = 10
		prefetchSubscription = queuePrefetch
			.collect(.byTime(DispatchQueue.main, 0.1)) // Wanted to use .throttle(for: 0.1, scheduler: DispatchQueue(label: "ASCollectionView PREFETCH"), latest: true) -> THIS CRASHES?? BUG??
			.compactMap
		{ _ in
			self.collectionViewController?.collectionView.indexPathsForVisibleItems
		}
		.receive(on: DispatchQueue.global(qos: .background))
		.map
		{ visibleIndexPaths -> [Int: [IndexPath]] in
			let visibleIndexPathsBySection = Dictionary(grouping: visibleIndexPaths) { $0.section }.compactMapValues
			{ (indexPaths) -> (section: Int, first: Int, last: Int)? in
				guard let first = indexPaths.min(), let last = indexPaths.max() else { return nil }
				return (section: first.section, first: first.item, last: last.item)
			}
			var toPrefetch: [Int: [IndexPath]] = visibleIndexPathsBySection.mapValues
			{ item in
				let sectionIndexPaths = self.parent.sections[item.section].dataSource.getIndexPaths(withSectionIndex: item.section)
				let nextItemsInSection: ArraySlice<IndexPath> = {
					guard (item.last + 1) < sectionIndexPaths.endIndex else { return [] }
					return sectionIndexPaths[(item.last + 1)..<min(item.last + numberToPreload + 1, sectionIndexPaths.endIndex)]
				}()
				let previousItemsInSection: ArraySlice<IndexPath> = {
					guard (item.first - 1) >= sectionIndexPaths.startIndex else { return [] }
					return sectionIndexPaths[max(sectionIndexPaths.startIndex, item.first - numberToPreload)..<item.first]
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
		{ prefetch in
			prefetch.forEach
			{ sectionIndex, toPrefetch in
				if !toPrefetch.isEmpty
				{
					self.parent.sections[sectionIndex].dataSource.prefetch(toPrefetch)
				}
				let toCancel = Array(self.currentlyPrefetching.filter { $0.section == sectionIndex }.subtracting(toPrefetch))
				if !toCancel.isEmpty
				{
					self.parent.sections[sectionIndex].dataSource.cancelPrefetch(toCancel)
				}
			}

			self.currentlyPrefetching = Set(prefetch.flatMap { $0.value })
		}
	}
}

public enum ASCollectionViewScrollPosition
{
	case top
	case bottom
	case left
	case right
	case centerOnIndexPath(_: IndexPath)
}

public class AS_CollectionViewController: UIViewController
{
	weak var coordinator: ASCollectionViewCoordinator?

	var collectionViewLayout: UICollectionViewLayout
	lazy var collectionView: UICollectionView = {
		UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
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

	public override func viewDidLoad()
	{
		super.viewDidLoad()
		view.backgroundColor = .clear
		view.addSubview(collectionView)
		collectionView.backgroundColor = .clear

		collectionView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
			collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
		])
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

	func shrinkToContentSize(isEnabled: Bool, _ contentSize: Binding<CGSize?>, dimensionToShrink: ShrinkDimension) -> some View
	{
		SelfSizingWrapper(self, isEnabled: isEnabled, contentSize: contentSize, shrinkDirection: dimensionToShrink)
	}
}

protocol ContentSize
{
	var contentSize: Binding<CGSize?>? { get set }
}

// MARK: Helpers for self-sizing collection

public enum ShrinkDimension
{
	case horizontal
	case vertical

	var shrinkVertical: Bool
	{
		self == .vertical
	}

	var shrinkHorizontal: Bool
	{
		self == .horizontal
	}
}

struct SelfSizingWrapper<Content: View & ContentSize>: View
{
	var contentSize: Binding<CGSize?>
	var content: Content
	var shrinkDirection: ShrinkDimension
	var isEnabled: Bool

	init(_ content: Content, isEnabled: Bool, contentSize: Binding<CGSize?>, shrinkDirection: ShrinkDimension)
	{
		self.content = content
		self.contentSize = contentSize
		self.shrinkDirection = shrinkDirection
		self.isEnabled = isEnabled

		self.content.contentSize = contentSize
	}

	var body: some View
	{
		content
			.frame(
				idealWidth: isEnabled && shrinkDirection.shrinkHorizontal ? contentSize.wrappedValue?.width : nil,
				maxWidth: isEnabled && shrinkDirection.shrinkHorizontal ? contentSize.wrappedValue?.width : nil,
				idealHeight: isEnabled && shrinkDirection.shrinkVertical ? contentSize.wrappedValue?.height : nil,
				maxHeight: isEnabled && shrinkDirection.shrinkVertical ? contentSize.wrappedValue?.height : nil,
				alignment: .topLeading)
	}
}
