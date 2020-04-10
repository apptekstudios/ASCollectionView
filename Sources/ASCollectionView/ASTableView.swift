// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

@available(iOS 13.0, *)
extension ASTableView where SectionID == Int
{
	/**
	 Initializes a  table view with a single section.

	 - Parameters:
	 - section: A single section (ASTableViewSection)
	 */
	public init(style: UITableView.Style = .plain, section: Section)
	{
		self.style = style
		sections = [section]
	}

	/**
	 Initializes a  table view with a single section.
	 */
	public init<DataCollection: RandomAccessCollection, DataID: Hashable, Content: View>(
		style: UITableView.Style = .plain,
		data: DataCollection,
		dataID dataIDKeyPath: KeyPath<DataCollection.Element, DataID>,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, CellContext) -> Content))
		where DataCollection.Index == Int
	{
		self.style = style
		let section = ASSection(
			id: 0,
			data: data,
			dataID: dataIDKeyPath,
			contentBuilder: contentBuilder)
		sections = [section]
	}

	/**
	 Initializes a  table view with a single section of identifiable data
	 */
	public init<DataCollection: RandomAccessCollection, Content: View>(
		style: UITableView.Style = .plain,
		data: DataCollection,
		@ViewBuilder contentBuilder: @escaping ((DataCollection.Element, CellContext) -> Content))
		where DataCollection.Index == Int, DataCollection.Element: Identifiable
	{
		self.init(style: style, data: data, dataID: \.id, contentBuilder: contentBuilder)
	}

	/**
	 Initializes a  table view with a single section of static content
	 */
	public static func `static`(@ViewArrayBuilder staticContent: () -> ViewArrayBuilder.Wrapper) -> ASTableView
	{
		ASTableView(
			style: .plain,
			sections: [ASTableViewSection(id: 0, content: staticContent)])
	}
}

@available(iOS 13.0, *)
public typealias ASTableViewSection = ASSection

@available(iOS 13.0, *)
public struct ASTableView<SectionID: Hashable>: UIViewControllerRepresentable, ContentSize
{
	// MARK: Type definitions

	public typealias Section = ASTableViewSection<SectionID>

	public typealias OnScrollCallback = ((_ contentOffset: CGPoint, _ contentSize: CGSize) -> Void)
	public typealias OnReachedBottomCallback = (() -> Void)

	// MARK: Key variables

	public var sections: [Section]
	public var style: UITableView.Style

	// MARK: Private vars set by public modifiers

	private var onScrollCallback: OnScrollCallback?
	private var onReachedBottomCallback: OnReachedBottomCallback?

	private var scrollIndicatorEnabled: Bool = true
	private var contentInsets: UIEdgeInsets = .zero

	private var separatorsEnabled: Bool = true

	private var onPullToRefresh: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?

	private var alwaysBounce: Bool = false
	private var animateOnDataRefresh: Bool = true

	// MARK: Environment variables

	@Environment(\.editMode) private var editMode

	// Other
	var contentSizeTracker: ContentSizeTracker?

	/**
	 Initializes a  table view with the given sections

	 - Parameters:
	 - sections: An array of sections (ASTableViewSection)
	 */
	@inlinable public init(style: UITableView.Style = .plain, sections: [Section])
	{
		self.style = style
		self.sections = sections
	}

	@inlinable public init(style: UITableView.Style = .plain, @SectionArrayBuilder <SectionID> sectionBuilder: () -> [Section])
	{
		self.style = style
		sections = sectionBuilder()
	}

	public func makeUIViewController(context: Context) -> AS_TableViewController
	{
		context.coordinator.parent = self

		let tableViewController = AS_TableViewController(style: style)
		tableViewController.coordinator = context.coordinator

		context.coordinator.tableViewController = tableViewController
		context.coordinator.updateTableViewSettings(tableViewController.tableView)

		context.coordinator.setupDataSource(forTableView: tableViewController.tableView)
		return tableViewController
	}

	public func updateUIViewController(_ tableViewController: AS_TableViewController, context: Context)
	{
		context.coordinator.parent = self
		context.coordinator.updateTableViewSettings(tableViewController.tableView)
		context.coordinator.updateContent(tableViewController.tableView, transaction: context.transaction, refreshExistingCells: true)
		context.coordinator.configureRefreshControl(for: tableViewController.tableView)
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
		sections.forEach {
			let (inserted, _) = sectionIDs.insert($0.id)
			if !inserted
			{
				conflicts.insert($0.id)
			}
		}
		if !conflicts.isEmpty
		{
			print("ASTABLEVIEW: The following section IDs are used more than once, please use unique section IDs to avoid unexpected behaviour:", sectionIDs)
		}
	}
#endif

	public class Coordinator: NSObject, ASTableViewCoordinator, UITableViewDelegate, UITableViewDataSourcePrefetching, UITableViewDragDelegate, UITableViewDropDelegate
	{
		var parent: ASTableView
		weak var tableViewController: AS_TableViewController?

		var dataSource: ASDiffableDataSourceTableView<SectionID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString

		// MARK: Private tracking variables

		private var hasDoneInitialSetup = false
		private var lastSnapshot: NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>?

		// MARK: Caching

		private var autoCachingHostingControllers = ASPriorityCache<ASCollectionViewItemUniqueID, ASHostingControllerProtocol>()
		private var explicitlyCachedHostingControllers: [ASCollectionViewItemUniqueID: ASHostingControllerProtocol] = [:]

		typealias Cell = ASTableViewCell

		init(_ parent: ASTableView)
		{
			self.parent = parent
		}

		func itemID(for indexPath: IndexPath) -> ASCollectionViewItemUniqueID?
		{
			guard
				let sectionID = sectionID(fromSectionIndex: indexPath.section)
			else { return nil }
			return parent.sections[safe: indexPath.section]?.dataSource.getItemID(for: indexPath.item, withSectionID: sectionID)
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

		func updateTableViewSettings(_ tableView: UITableView)
		{
			assignIfChanged(tableView, \.backgroundColor, newValue: (parent.style == .plain) ? .clear : .systemGroupedBackground)
			assignIfChanged(tableView, \.separatorStyle, newValue: parent.separatorsEnabled ? .singleLine : .none)
			assignIfChanged(tableView, \.contentInset, newValue: parent.contentInsets)
			assignIfChanged(tableView, \.alwaysBounceVertical, newValue: parent.alwaysBounce)
			assignIfChanged(tableView, \.showsVerticalScrollIndicator, newValue: parent.scrollIndicatorEnabled)
			assignIfChanged(tableView, \.showsHorizontalScrollIndicator, newValue: parent.scrollIndicatorEnabled)
			assignIfChanged(tableView, \.keyboardDismissMode, newValue: .onDrag)

			let isEditing = parent.editMode?.wrappedValue.isEditing ?? false
			assignIfChanged(tableView, \.allowsSelection, newValue: isEditing)
			assignIfChanged(tableView, \.allowsMultipleSelection, newValue: isEditing)
		}

		func setupDataSource(forTableView tv: UITableView)
		{
			tv.delegate = self
			tv.prefetchDataSource = self

			tv.dragDelegate = self
			tv.dropDelegate = self
			tv.dragInteractionEnabled = true

			tv.register(Cell.self, forCellReuseIdentifier: cellReuseID)
			tv.register(ASTableViewSupplementaryView.self, forHeaderFooterViewReuseIdentifier: supplementaryReuseID)

			dataSource = .init(tableView: tv)
			{ [weak self] tableView, indexPath, itemID in
				guard let self = self else { return nil }
				guard
					let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseID, for: indexPath) as? Cell
				else { return nil }

				guard let section = self.parent.sections[safe: indexPath.section] else { return cell }

				cell.backgroundColor = (self.parent.style == .plain) ? .clear : .secondarySystemGroupedBackground

				// Cell layout invalidation callback
				cell.invalidateLayoutCallback = { [weak self] animated in
					self?.reloadRow(indexPath, animated: animated)
				}
				cell.scrollToCellCallback = { [weak self] position in
					self?.scrollToRow(indexPath: indexPath, position: position)
				}

				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .content, indexPath: indexPath)
				cell.selfSizingConfig =
					section.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? ASSelfSizingConfig(selfSizeHorizontally: false, selfSizeVertically: true)

				// Set itemID
				cell.itemID = itemID

				// Update hostingController
				let cachedHC = self.explicitlyCachedHostingControllers[itemID] ?? self.autoCachingHostingControllers[itemID]
				cell.hostingController = section.dataSource.updateOrCreateHostController(forItemID: itemID, existingHC: cachedHC)
				// Cache the HC
				self.autoCachingHostingControllers[itemID] = cell.hostingController
				if section.shouldCacheCells
				{
					self.explicitlyCachedHostingControllers[itemID] = cell.hostingController
				}

				return cell
			}
			dataSource?.defaultRowAnimation = .none
		}

		func populateDataSource(animated: Bool = true)
		{
			guard hasDoneInitialSetup else { return }
			let snapshot = ASDiffableDataSourceSnapshot(sections:
				parent.sections.map {
					ASDiffableDataSourceSnapshot.Section(id: $0.id, elements: $0.itemIDs)
				}
			)
			dataSource?.applySnapshot(snapshot, animated: animated)
			tableViewController.map { self.didUpdateContentSize($0.tableView.contentSize) }
		}

		func updateContent(_ tv: UITableView, transaction: Transaction?, refreshExistingCells: Bool)
		{
			guard hasDoneInitialSetup else { return }
			if refreshExistingCells
			{
				withAnimation(parent.animateOnDataRefresh ? transaction?.animation : nil) {
					for case let cell as Cell in tv.visibleCells
					{
						guard
							let itemID = cell.itemID,
							let hc = cell.hostingController
						else { return }
						self.section(forItemID: itemID)?.dataSource.update(hc, forItemID: itemID)
					}

					tv.visibleHeaderViews.forEach { sectionIndex, view in
						configureHeader(view, forSection: sectionIndex)
					}

					tv.visibleFooterViews.forEach { sectionIndex, view in
						configureFooter(view, forSection: sectionIndex)
					}
				}
			}
			let transactionAnimationEnabled = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			populateDataSource(animated: parent.animateOnDataRefresh && transactionAnimationEnabled)
			updateSelectionBindings(tv)
		}

		func reloadRow(_ indexPath: IndexPath, animated: Bool)
		{
			dataSource?.reloadItem(indexPath, animated: animated)
		}

		func scrollToRow(indexPath: IndexPath, position: UITableView.ScrollPosition = .none)
		{
			tableViewController?.tableView.scrollToRow(at: indexPath, at: position, animated: true)
		}

		func onMoveToParent()
		{
			if !hasDoneInitialSetup
			{
				hasDoneInitialSetup = true

				// Populate data source
				populateDataSource(animated: false)

				// Check if reached bottom already
				tableViewController.map { checkIfReachedBottom($0.tableView) }
			}
		}

		func onMoveFromParent()
		{}

		// MARK: Function for updating contentSize binding

		var lastContentSize: CGSize = .zero
		func didUpdateContentSize(_ size: CGSize)
		{
			guard let tv = tableViewController?.tableView, tv.contentSize != lastContentSize else { return }
			lastContentSize = tv.contentSize
			parent.contentSizeTracker?.contentSize = size
		}

		func configureRefreshControl(for tv: UITableView)
		{
			guard parent.onPullToRefresh != nil else
			{
				if tv.refreshControl != nil
				{
					tv.refreshControl = nil
				}
				return
			}
			if tv.refreshControl == nil
			{
				let refreshControl = UIRefreshControl()
				refreshControl.addTarget(self, action: #selector(tableViewDidPullToRefresh), for: .valueChanged)
				tv.refreshControl = refreshControl
			}
		}

		@objc
		public func tableViewDidPullToRefresh()
		{
			guard let tableView = tableViewController?.tableView else { return }
			let endRefreshing: (() -> Void) = { [weak tableView] in
				tableView?.refreshControl?.endRefreshing()
			}
			parent.onPullToRefresh?(endRefreshing)
		}

		public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			tableViewController.map { (cell as? Cell)?.willAppear(in: $0) }
			parent.sections[safe: indexPath.section]?.dataSource.onAppear(indexPath)
		}

		public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			parent.sections[safe: indexPath.section]?.dataSource.onDisappear(indexPath)
		}

		public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
		{
			(view as? ASTableViewSupplementaryView)?.willAppear(in: tableViewController)
		}

		public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int)
		{
			(view as? ASTableViewSupplementaryView)?.didDisappear()
		}

		public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
		{
			(view as? ASTableViewSupplementaryView)?.willAppear(in: tableViewController)
		}

		public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int)
		{
			(view as? ASTableViewSupplementaryView)?.didDisappear()
		}

		public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath])
		{
			let itemIDsToPrefetchBySection: [Int: [IndexPath]] = Dictionary(grouping: indexPaths) { $0.section }
			itemIDsToPrefetchBySection.forEach
			{
				parent.sections[safe: $0.key]?.dataSource.prefetch($0.value)
			}
		}

		public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath])
		{
			let itemIDsToCancelPrefetchBySection: [Int: [IndexPath]] = Dictionary(grouping: indexPaths) { $0.section }
			itemIDsToCancelPrefetchBySection.forEach
			{
				parent.sections[safe: $0.key]?.dataSource.cancelPrefetch($0.value)
			}
		}

		// MARK: Swipe actions

		public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
		{
			guard parent.sections[safe: indexPath.section]?.dataSource.supportsDelete(at: indexPath) == true else { return nil }
			let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
				self?.onDeleteAction(indexPath: indexPath, completionHandler: completionHandler)
			}
			return UISwipeActionsConfiguration(actions: [deleteAction])
		}

		public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle
		{
			.none
		}

		private func onDeleteAction(indexPath: IndexPath, completionHandler: (Bool) -> Void)
		{
			parent.sections[safe: indexPath.section]?.dataSource.onDelete(indexPath: indexPath, completionHandler: completionHandler)
		}

		// MARK: Cell Selection

		public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
		{
			updateContent(tableView, transaction: nil, refreshExistingCells: true)
		}

		public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
		{
			updateContent(tableView, transaction: nil, refreshExistingCells: true)
		}

		func updateSelectionBindings(_ tableView: UITableView)
		{
			let selected = tableView.indexPathsForSelectedRows ?? []
			let selectionBySection = Dictionary(grouping: selected) { $0.section }
				.mapValues
			{
				Set($0.map { $0.item })
			}
			parent.sections.enumerated().forEach { offset, section in
				section.dataSource.updateSelection(selectionBySection[offset] ?? [])
			}
		}

		public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
		{
			guard parent.sections[safe: indexPath.section]?.dataSource.shouldSelect(indexPath) ?? false else
			{
				return nil
			}
			return indexPath
		}

		public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
		{
			guard parent.sections[safe: indexPath.section]?.dataSource.shouldDeselect(indexPath) ?? false else
			{
				return nil
			}
			return indexPath
		}

		public func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
		{
			guard !indexPath.isEmpty else { return [] }
			guard let dragItem = parent.sections[safe: indexPath.section]?.dataSource.getDragItem(for: indexPath) else { return [] }
			return [dragItem]
		}

		func canDrop(at indexPath: IndexPath) -> Bool
		{
			guard !indexPath.isEmpty else { return false }
			return parent.sections[safe: indexPath.section]?.dataSource.dropEnabled ?? false
		}

		public func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal
		{
			if tableView.hasActiveDrag
			{
				if let destination = destinationIndexPath
				{
					guard canDrop(at: destination) else
					{
						return UITableViewDropProposal(operation: .cancel)
					}
				}
				return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
			}
			else
			{
				return UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
			}
		}

		public func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator)
		{
			guard
				let destinationIndexPath = coordinator.destinationIndexPath,
				!destinationIndexPath.isEmpty,
				let destinationSection = parent.sections[safe: destinationIndexPath.section]
			else { return }

			switch coordinator.proposal.operation
			{
			case .move:
				let itemsBySourceSection = Dictionary(grouping: coordinator.items) { item -> Int? in
					if let sourceIndex = item.sourceIndexPath, !sourceIndex.isEmpty
					{
						return sourceIndex.section
					}
					else
					{
						return nil
					}
				}

				// Handle move within destination section + insertion from other sections
				let itemsToMove = itemsBySourceSection[destinationIndexPath.section] ?? []
				var itemsToInsertPrefix: [UITableViewDropItem] = []
				var itemsToInsertSuffix: [UITableViewDropItem] = []

				// Handle removal from source sections
				for (sectionIndex, items) in itemsBySourceSection
				{
					guard
						let sectionIndex = sectionIndex,
						sectionIndex != destinationIndexPath.section,
						let sourceSection = parent.sections[safe: sectionIndex]
					else { continue }
					// Note that these need to be inserted at destination
					if sectionIndex < destinationIndexPath.section
					{
						itemsToInsertPrefix.append(contentsOf: coordinator.items)
					}
					else
					{
						itemsToInsertSuffix.append(contentsOf: coordinator.items)
					}

					let itemsSourceIndexSet = IndexSet(items.compactMap { $0.sourceIndexPath?.item })
					// These items are being REMOVED from the section (moved to another section)
					let removeOperation = DragDrop<UIDragItem>.onRemoveItems(from: itemsSourceIndexSet)
					sourceSection.dataSource.applyDragOperation(removeOperation)
				}

				// Find index after accounting for moves
				let itemsToMoveSourceIndexSet = IndexSet(itemsToMove.compactMap { $0.sourceIndexPath?.item })
				// Adjusted destination index, note that this can exceed the usual highest index (due to the way the move is calculated)
				let adjustedDestinationIndexForMove = itemsToMoveSourceIndexSet.reduce(into: destinationIndexPath.item) {
					if $1 < $0 { $0 += 1 }
				}

				//Insert the suffix after
				let adjustedDestinationIndexForSuffix = destinationIndexPath.item + itemsToMoveSourceIndexSet.count
				let adjustedDestinationIndexForPrefix = destinationIndexPath.item

				// Calculate move within destination section
				let moveOperation: DragDrop<UIDragItem>? = (!itemsToMoveSourceIndexSet.isEmpty) ? DragDrop<UIDragItem>.onMoveItems(from: itemsToMoveSourceIndexSet, to: adjustedDestinationIndexForMove) : nil

				// Calculate insert suffix and prefix
				let insertSuffixOperation: DragDrop<UIDragItem>? = (!itemsToInsertSuffix.isEmpty) ? DragDrop<UIDragItem>.onInsertItems(items: itemsToInsertSuffix.compactMap { $0.dragItem }, to: adjustedDestinationIndexForSuffix) : nil
				let insertPrefixOperation: DragDrop<UIDragItem>? = (!itemsToInsertPrefix.isEmpty) ? DragDrop<UIDragItem>.onInsertItems(items: itemsToInsertPrefix.compactMap { $0.dragItem }, to: adjustedDestinationIndexForPrefix) : nil

				// Apply operation: MOVE THEN INSERT SUFFIX, THEN INSERT PREFIX (that order is important)
				moveOperation.map { destinationSection.dataSource.applyDragOperation($0) }
				insertSuffixOperation.map { destinationSection.dataSource.applyDragOperation($0) } // Suffix first so that prefix index unaffected
				insertPrefixOperation.map { destinationSection.dataSource.applyDragOperation($0) }

			case .copy:
				let items = coordinator.items.map { $0.dragItem }
				if !items.isEmpty
				{
					let operation = DragDrop<UIDragItem>.onInsertItems(items: items, to: destinationIndexPath.item)
					destinationSection.dataSource.applyDragOperation(operation)
				}

			default:
				return
			}
		}

		public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
		{
			guard parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionHeader) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return parent.sections[safe: section]?.estimatedHeaderHeight ?? 50
		}

		public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
		{
			guard parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionHeader) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return UITableView.automaticDimension
		}

		public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
		{
			guard parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionFooter) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return parent.sections[safe: section]?.estimatedFooterHeight ?? 50
		}

		public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
		{
			guard parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionFooter) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return UITableView.automaticDimension
		}

		public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: supplementaryReuseID) else { return nil }
			configureHeader(reusableView, forSection: section)
			return reusableView
		}

		func configureHeader(_ headerCell: UITableViewHeaderFooterView, forSection section: Int)
		{
			guard let reusableView = headerCell as? ASTableViewSupplementaryView
			else { return }
			if let supplementaryView = parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionHeader)
			{
				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .supplementary(UICollectionView.elementKindSectionHeader), indexPath: IndexPath(row: 0, section: section))
				reusableView.selfSizingConfig =
					parent.sections[safe: section]?.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? ASSelfSizingConfig(selfSizeHorizontally: false, selfSizeVertically: true)

				// Cell Content Setup
				reusableView.setupFor(
					id: section,
					view: supplementaryView)
			}
			else
			{
				reusableView.setupForEmpty(id: section)
			}
		}

		public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: supplementaryReuseID) else { return nil }
			configureFooter(reusableView, forSection: section)
			return reusableView
		}

		func configureFooter(_ footerCell: UITableViewHeaderFooterView, forSection section: Int)
		{
			guard let reusableView = footerCell as? ASTableViewSupplementaryView
			else { return }
			if let supplementaryView = parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionFooter)
			{
				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .supplementary(UICollectionView.elementKindSectionFooter), indexPath: IndexPath(row: 0, section: section))
				reusableView.selfSizingConfig =
					parent.sections[safe: section]?.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? ASSelfSizingConfig(selfSizeHorizontally: false, selfSizeVertically: true)

				// Cell Content Setup
				reusableView.setupFor(
					id: section,
					view: supplementaryView)
			}
			else
			{
				reusableView.setupForEmpty(id: section)
			}
		}

		// MARK: Context Menu Support

		public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
		{
			guard !indexPath.isEmpty else { return nil }
			return parent.sections[safe: indexPath.section]?.dataSource.getContextMenu(for: indexPath)
		}

		public func scrollViewDidScroll(_ scrollView: UIScrollView)
		{
			parent.onScrollCallback?(scrollView.contentOffset, scrollView.contentSizePlusInsets)
			checkIfReachedBottom(scrollView)
		}

		var hasAlreadyReachedBottom: Bool = false
		func checkIfReachedBottom(_ scrollView: UIScrollView)
		{
			if (scrollView.contentSize.height - scrollView.contentOffset.y) <= scrollView.frame.size.height
			{
				if !hasAlreadyReachedBottom
				{
					hasAlreadyReachedBottom = true
					parent.onReachedBottomCallback?()
				}
			}
			else
			{
				hasAlreadyReachedBottom = false
			}
		}
	}
}

@available(iOS 13.0, *)
protocol ASTableViewCoordinator: AnyObject
{
	func onMoveToParent()
	func onMoveFromParent()
	func didUpdateContentSize(_ size: CGSize)
}

// MARK: PUBLIC Modifier: OnScroll / OnReachedBottom

@available(iOS 13.0, *)
public extension ASTableView
{
	/// Set a closure that is called whenever the tableView is scrolled
	func onScroll(_ onScroll: @escaping OnScrollCallback) -> Self
	{
		var this = self
		this.onScrollCallback = onScroll
		return this
	}

	/// Set a closure that is called whenever the tableView is scrolled to the bottom.
	/// This is useful to enable loading more data when scrolling to bottom
	func onReachedBottom(_ onReachedBottom: @escaping OnReachedBottomCallback) -> Self
	{
		var this = self
		this.onReachedBottomCallback = onReachedBottom
		return this
	}

	/// Set whether to show separators between cells
	func separatorsEnabled(_ isEnabled: Bool = true) -> Self
	{
		var this = self
		this.separatorsEnabled = isEnabled
		return this
	}

	/// Set whether to show scroll indicator
	func scrollIndicatorEnabled(_ isEnabled: Bool = true) -> Self
	{
		var this = self
		this.scrollIndicatorEnabled = isEnabled
		return this
	}

	/// Set the content insets
	func contentInsets(_ insets: UIEdgeInsets) -> Self
	{
		var this = self
		this.contentInsets = insets
		return this
	}

	/// Set a closure that is called when the tableView is pulled to refresh
	func onPullToRefresh(_ callback: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?) -> Self
	{
		var this = self
		this.onPullToRefresh = callback
		return this
	}

	/// Set whether the TableView should always allow bounce vertically
	func alwaysBounce(_ alwaysBounce: Bool = true) -> Self
	{
		var this = self
		this.alwaysBounce = alwaysBounce
		return this
	}

	/// Set whether the TableView should animate on data refresh
	func animateOnDataRefresh(_ animate: Bool = true) -> Self
	{
		var this = self
		this.animateOnDataRefresh = animate
		return this
	}
}

// MARK: ASTableView specific header modifiers

@available(iOS 13.0, *)
public extension ASTableViewSection
{
	func sectionHeaderInsetGrouped<Content: View>(content: () -> Content?) -> Self
	{
		var section = self
		let insetGroupedContent =
			HStack {
				content()
				Spacer()
			}
			.font(.headline)
			.padding(EdgeInsets(top: 12, leading: 0, bottom: 6, trailing: 0))

		section.setHeaderView(insetGroupedContent)
		return section
	}
}

@available(iOS 13.0, *)
public class AS_TableViewController: UIViewController
{
	weak var coordinator: ASTableViewCoordinator?
	{
		didSet
		{
			guard viewIfLoaded != nil else { return }
			tableView.coordinator = coordinator
		}
	}

	var style: UITableView.Style

	lazy var tableView: AS_UITableView = {
		let tableView = AS_UITableView(frame: .zero, style: style)
		tableView.coordinator = coordinator
		tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude))) // Remove unnecessary padding in Style.grouped/insetGrouped
		tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.leastNormalMagnitude, height: 10))) // Remove separators for non-existent cells
		return tableView
	}()

	public init(style: UITableView.Style)
	{
		self.style = style
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	public override func loadView()
	{
		view = tableView
	}

	public override func viewDidLoad()
	{
		super.viewDidLoad()
	}

	public override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		coordinator?.didUpdateContentSize(tableView.contentSize)
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
}

@available(iOS 13.0, *)
class AS_UITableView: UITableView
{
	weak var coordinator: ASTableViewCoordinator?

	public override func didMoveToWindow()
	{
		super.didMoveToWindow()

		// Intended as a temporary workaround for a SwiftUI bug present in 13.3 -> the UIViewController is not moved to a parent when embedded in a list/scrollview
		coordinator?.onMoveToParent()
	}
}
