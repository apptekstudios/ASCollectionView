// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

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
	public var editMode: Bool = false

	// MARK: Private vars set by public modifiers

	internal var onScrollCallback: OnScrollCallback?
	internal var onReachedBottomCallback: OnReachedBottomCallback?

	internal var scrollPositionSetter: Binding<ASTableViewScrollPosition?>?

	internal var scrollIndicatorEnabled: Bool = true
	internal var contentInsets: UIEdgeInsets = .zero

	internal var separatorsEnabled: Bool = true

	internal var onPullToRefresh: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?
    
    internal var onWillDisplay: ((UITableViewCell, IndexPath) -> Void)?
    
    internal var onDidDisplay: ((UITableViewCell, IndexPath) -> Void)?

	internal var alwaysBounce: Bool = false
	internal var animateOnDataRefresh: Bool = true

	internal var dodgeKeyboard: Bool = true

	internal var shouldHandleKeyboardAppereance: Bool = true

	// MARK: Environment variables

	@Environment(\.invalidateCellLayout) var invalidateParentCellLayout // Call this if using content size binding (nested inside another ASCollectionView)

	// Other
	var contentSizeTracker: ContentSizeTracker?

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
		context.coordinator.updateContent(tableViewController.tableView, transaction: context.transaction)
		context.coordinator.configureRefreshControl(for: tableViewController.tableView)
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
			print("ASTABLEVIEW: The following section IDs are used more than once, please use unique section IDs to avoid unexpected behaviour:", conflicts)
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
		private var shouldAnimateScrollPositionSet = false
		private var selectedIndexPaths: Set<IndexPath> = []

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
			assignIfChanged(tableView, \.alwaysBounceVertical, newValue: parent.alwaysBounce)
			assignIfChanged(tableView, \.showsVerticalScrollIndicator, newValue: parent.scrollIndicatorEnabled)
			assignIfChanged(tableView, \.showsHorizontalScrollIndicator, newValue: parent.scrollIndicatorEnabled)
			assignIfChanged(tableView, \.keyboardDismissMode, newValue: .interactive)

			updateTableViewContentInsets(tableView)

			assignIfChanged(tableView, \.allowsSelection, newValue: true)
			assignIfChanged(tableView, \.allowsMultipleSelection, newValue: true)
			assignIfChanged(tableView, \.allowsSelectionDuringEditing, newValue: true)
			assignIfChanged(tableView, \.allowsMultipleSelectionDuringEditing, newValue: true)
			assignIfChanged(tableView, \.isEditing, newValue: parent.editMode)
		}

		func updateTableViewContentInsets(_ tableView: UITableView)
		{
			assignIfChanged(tableView, \.contentInset, newValue: adaptiveContentInsets)
		}

		func isIndexPathSelected(_ indexPath: IndexPath) -> Bool
		{
			tableViewController?.tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
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
				cell.tableViewController = self.tableViewController

				guard let section = self.parent.sections[safe: indexPath.section] else { return cell }

				cell.backgroundColor = (self.parent.style == .plain || section.disableDefaultTheming) ? .clear : .secondarySystemGroupedBackground

				cell.separatorInset = section.tableViewSeparatorInsets ?? UIEdgeInsets(top: 0, left: UITableView.automaticDimension, bottom: 0, right: UITableView.automaticDimension)

				cell.isSelected = self.isIndexPathSelected(indexPath)

				cell.setContent(itemID: itemID, content: section.dataSource.content(forItemID: itemID))

				cell.disableSwiftUIDropInteraction = section.dataSource.dropEnabled
				cell.disableSwiftUIDragInteraction = section.dataSource.dragEnabled

				cell.hostingController.invalidateCellLayoutCallback = { [weak self, weak cell] animated in
					self?.invalidateLayout(animated: animated, cell: cell)
				}
				cell.hostingController.tableViewScrollToCellCallback = { [weak self] position in
					self?.scrollToRow(indexPath: indexPath, position: position)
				}

				return cell
			}

			dataSource?.canSelect = { [weak self] indexPath -> Bool in
				self?.canSelect(indexPath) ?? false
			}
			dataSource?.canDelete = { [weak self] indexPath -> Bool in
				self?.canDelete(indexPath) ?? false
			}
			dataSource?.onDelete = { [weak self] indexPath -> Bool in
				self?.onDeleteAction(indexPath: indexPath) ?? false
			}
			dataSource?.canMove = { [weak self] indexPath -> Bool in
				self?.canMove(indexPath) ?? false
			}
			dataSource?.onMove = { [weak self] from, to in
				self?.onMoveAction(from: from, to: to) ?? false
			}
		}

		func populateDataSource(animated: Bool = true, transaction: Transaction? = nil)
		{
			guard hasDoneInitialSetup else { return }
			let snapshot = ASDiffableDataSourceSnapshot(sections:
				parent.sections.map
				{
					ASDiffableDataSourceSnapshot.Section(id: $0.id, elements: $0.itemIDs)
				}
			)
			dataSource?.setIndexTitles(
				parent.sections.enumerated().compactMap
				{ (index, section) -> (Int, String)? in
					guard let indexTitle = section.sectionIndexTitle else { return nil }
					return (index, indexTitle)
				}
			)

			dataSource?.applySnapshot(snapshot, animated: animated)
			shouldAnimateScrollPositionSet = animated

			refreshVisibleCells(transaction: transaction, updateAll: false)
		}

		func updateContent(_ tv: UITableView, transaction: Transaction?)
		{
			guard hasDoneInitialSetup else { return }

			let transactionAnimationEnabled = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			populateDataSource(animated: parent.animateOnDataRefresh && transactionAnimationEnabled, transaction: transaction)

			dataSource?.updateCellSizes(animated: transactionAnimationEnabled)
			updateSelection(tv, transaction: transaction)
		}

		func refreshVisibleCells(transaction: Transaction?, updateAll: Bool = true)
		{
			guard let tv = tableViewController?.tableView else { return }
			for cell in tv.visibleCells
			{
				refreshCell(cell)
			}

			for case let supplementaryView as ASTableViewSupplementaryView in tv.subviews
			{
				guard
					let supplementaryID = supplementaryView.supplementaryID,
					let section = parent.sections.first(where: { $0.id.hashValue == supplementaryID.sectionIDHash })
				else { continue }
				supplementaryView.setContent(supplementaryID: supplementaryID, content: section.dataSource.content(supplementaryID: supplementaryID))
			}
		}

		func refreshCell(_ cell: UITableViewCell, forceUpdate: Bool = false)
		{
			guard
				let cell = cell as? Cell,
				let itemID = cell.itemID,
				let section = section(forItemID: itemID)
			else { return }

			cell.setContent(itemID: itemID, content: section.dataSource.content(forItemID: itemID))
			cell.disableSwiftUIDropInteraction = section.dataSource.dropEnabled
			cell.disableSwiftUIDragInteraction = section.dataSource.dragEnabled
		}

		func invalidateLayout(animated: Bool, cell: ASTableViewCell?)
		{
			dataSource?.updateCellSizes(animated: animated)
		}

		func scrollToRow(indexPath: IndexPath, position: UITableView.ScrollPosition = .none)
		{
			tableViewController?.tableView.scrollToRow(at: indexPath, at: position, animated: true)
		}

		func applyScrollPosition(animated: Bool)
		{
			if let scrollPositionToSet = parent.scrollPositionSetter?.wrappedValue
			{
				switch scrollPositionToSet
				{
				case let .indexPath(indexPath):
					tableViewController?.tableView.scrollToRow(at: indexPath, at: .none, animated: animated)
				case .top:
					let contentInsets = tableViewController?.tableView.contentInset ?? .zero
					tableViewController?.tableView.setContentOffset(CGPoint(x: 0, y: contentInsets.top), animated: animated)
				case .bottom:
					let maxOffset = tableViewController?.tableView.maxContentOffset ?? .zero
					tableViewController?.tableView.setContentOffset(maxOffset, animated: animated)
				}
				DispatchQueue.main.async
				{
					self.parent.scrollPositionSetter?.wrappedValue = nil
				}
			}
		}

		func onMoveToParent()
		{
			guard !hasDoneInitialSetup else { return }

			hasDoneInitialSetup = true
			populateDataSource(animated: false)
			tableViewController.map { checkIfReachedBottom($0.tableView) }
		}

		func onMoveFromParent()
		{
			hasDoneInitialSetup = false
			dataSource?.didDisappear()
		}

		// MARK: Function for updating contentSize binding

		var lastContentSize: CGSize = .zero
		func didUpdateContentSize(_ size: CGSize)
		{
			guard let tv = tableViewController?.tableView, tv.contentSize != lastContentSize, tv.contentSize.height != 0 else { return }
			let firstSize = lastContentSize == .zero
			lastContentSize = tv.contentSize
			parent.contentSizeTracker?.contentSize = size
			DispatchQueue.main.async
			{
				self.parent.invalidateParentCellLayout?(!firstSize)
			}

			applyScrollPosition(animated: shouldAnimateScrollPositionSet)
		}

		func configureRefreshControl(for tv: UITableView)
		{
			guard parent.onPullToRefresh != nil
			else
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
			parent.sections[safe: indexPath.section]?.dataSource.onAppear(indexPath)
            parent.onWillDisplay?(cell,indexPath)
        
        }

		public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			parent.sections[safe: indexPath.section]?.dataSource.onDisappear(indexPath)
            parent.onDidDisplay?(cell,indexPath)
		}

		public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
		{}

		public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int)
		{}

		public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
		{}

		public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int)
		{}

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
			let deleteAction = UIContextualAction(style: .destructive, title: "Delete")
			{ [weak self] _, _, completionHandler in
				let didDelete = self?.onDeleteAction(indexPath: indexPath) ?? false
				completionHandler(didDelete)
			}
			return UISwipeActionsConfiguration(actions: [deleteAction])
		}

		public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle
		{
			if parent.sections[safe: indexPath.section]?.dataSource.supportsDelete(at: indexPath) ?? false
			{
				return .delete
			}
			return .none
		}

		private func canDelete(_ indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.supportsDelete(at: indexPath) ?? false
		}

		private func onDeleteAction(indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.onDelete(indexPath: indexPath) ?? false
		}

		private func canMove(_ indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.supportsMove(indexPath) ?? false
		}

		private func onMoveAction(from: IndexPath, to: IndexPath) -> Bool
		{
			guard let sourceSection = parent.sections[safe: from.section],
				let destinationSection = parent.sections[safe: to.section],
				parent.sections[safe: from.section]?.dataSource.supportsMove(from: from, to: to) ?? true,
				parent.sections[safe: to.section]?.dataSource.supportsMove(from: from, to: to) ?? true
			else { return false }
			if from.section == to.section
			{
				return sourceSection.dataSource.applyMove(from: from, to: to)
			}
			else
			{
				if let item = sourceSection.dataSource.getDragItem(for: from)
				{
					sourceSection.dataSource.applyRemove(atOffsets: [from.item])
					return destinationSection.dataSource.applyInsert(items: [item], at: to.item)
				}
				else
				{
					return false
				}
			}
		}

		// MARK: Cell Selection

		private func canSelect(_ indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldSelect(indexPath) ?? false
		}

		public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldHighlight(indexPath) ?? true
		}

		public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
		{
			parent.sections[safe: indexPath.section]?.dataSource.highlightIndex(indexPath.item)
		}

		public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
		{
			parent.sections[safe: indexPath.section]?.dataSource.unhighlightIndex(indexPath.item)
		}

		public func tableView(_ tableView: UITableView, shouldSelectRowAt indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldSelect(indexPath) ?? true
		}

		public func tableView(_ tableView: UITableView, shouldDeselectRowAt indexPath: IndexPath) -> Bool
		{
			parent.sections[safe: indexPath.section]?.dataSource.shouldDeselect(indexPath) ?? true
		}

		public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
		{
			self.tableView(tableView, shouldSelectRowAt: indexPath) ? indexPath : nil
		}

		public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
		{
			self.tableView(tableView, shouldDeselectRowAt: indexPath) ? indexPath : nil
		}

		public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
		{
			updateSelection(tableView)
			parent.sections[safe: indexPath.section]?.dataSource.didSelect(indexPath)
		}

		public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
		{
			updateSelection(tableView)
		}

		func updateSelection(_ tableView: UITableView, transaction: Transaction? = nil)
		{
			let selectedInDataSource = selectedIndexPathsInDataSource
			let selectedInTableView = Set(tableView.indexPathsForSelectedRows ?? [])
			guard selectedInDataSource != selectedInTableView else { return }

			let newSelection = threeWayMerge(base: selectedIndexPaths, dataSource: selectedInDataSource, tableView: selectedInTableView)
			let (toDeselect, toSelect) = selectionDifferences(oldSelectedIndexPaths: selectedInTableView, newSelectedIndexPaths: newSelection)

			selectedIndexPaths = newSelection
			updateSelectionBindings(newSelection)
			updateSelectionInTableView(tableView, indexPathsToDeselect: toDeselect, indexPathsToSelect: toSelect, transaction: transaction)
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

		private func threeWayMerge(base: Set<IndexPath>, dataSource: Set<IndexPath>, tableView: Set<IndexPath>) -> Set<IndexPath>
		{
			// In case the data source and collection view are both different from base, default to the collection view
			base == tableView ? dataSource : tableView
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

		private func updateSelectionInTableView(_ tableView: UITableView, indexPathsToDeselect: Set<IndexPath>, indexPathsToSelect: Set<IndexPath>, transaction: Transaction? = nil)
		{
			let isAnimated = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			indexPathsToDeselect.forEach { tableView.deselectRow(at: $0, animated: isAnimated) }
			indexPathsToSelect.forEach { tableView.selectRow(at: $0, animated: isAnimated, scrollPosition: .none) }
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
					guard canDrop(at: destination)
					else
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

			guard canDrop(at: destinationIndexPath) else { return }

			guard let oldSnapshot = dataSource?.currentSnapshot else { return }
			var dragSnapshot = oldSnapshot

			switch coordinator.proposal.operation
			{
			case .move:
				guard destinationSection.dataSource.reorderingEnabled else { return }
				let itemsBySourceSection = Dictionary(grouping: coordinator.items)
				{ item -> Int? in
					if let sourceIndex = item.sourceIndexPath, !sourceIndex.isEmpty
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

				var itemsToInsert: [UITableViewDropItem] = []

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
				let safeDestinationIndex = min(destinationIndexPath.item, dragSnapshot.sections[destinationIndexPath.section].elements.endIndex)

				if destinationSection.dataSource.applyInsert(items: itemsToInsert.map(\.dragItem), at: safeDestinationIndex)
				{
					dragSnapshot.insertItems(itemsToInsertIDs, atSectionIndex: destinationIndexPath.section, atOffset: destinationIndexPath.item)
				}

			case .copy:
				_ = destinationSection.dataSource.applyInsert(items: coordinator.items.map(\.dragItem), at: destinationIndexPath.item)

			default: break
			}

			dataSource?.applySnapshot(dragSnapshot, animated: false)
			refreshVisibleCells(transaction: nil)
			if let dragItem = coordinator.items.first, let destination = coordinator.destinationIndexPath
			{
				if dragItem.sourceIndexPath != nil
				{
					coordinator.drop(dragItem.dragItem, toRowAt: destination)
				}
			}
		}

		public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
		{
			guard parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionHeader) != nil
			else
			{
				return CGFloat.leastNormalMagnitude
			}
			return UITableView.automaticDimension
		}

		public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
		{
			guard parent.sections[safe: section]?.supplementary(ofKind: UICollectionView.elementKindSectionFooter) != nil
			else
			{
				return CGFloat.leastNormalMagnitude
			}
			return UITableView.automaticDimension
		}

		public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: supplementaryReuseID) else { return nil }
			configureSupplementary(reusableView, supplementaryKind: UICollectionView.elementKindSectionHeader, forSection: section)
			return reusableView
		}

		public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: supplementaryReuseID) else { return nil }
			configureSupplementary(reusableView, supplementaryKind: UICollectionView.elementKindSectionFooter, forSection: section)
			return reusableView
		}

		func configureSupplementary(_ cell: UITableViewHeaderFooterView, supplementaryKind: String, forSection sectionIndex: Int)
		{
			guard let reusableView = cell as? ASTableViewSupplementaryView
			else { return }

			guard let section = parent.sections[safe: sectionIndex] else { reusableView.setAsEmpty(supplementaryID: nil); return }
			let supplementaryID = ASSupplementaryCellID(sectionIDHash: section.id.hashValue, supplementaryKind: supplementaryKind)

			reusableView.setContent(supplementaryID: supplementaryID, content: section.dataSource.content(supplementaryID: supplementaryID))
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

		// MARK: Keyboard support

		var areKeyboardObserversSetUp: Bool = false
		var keyboardFrame: CGRect?
		{
			didSet
			{
				tableViewController.map
				{
					updateTableViewContentInsets($0.tableView)
				}
			}
		}

		var shouldHandleKeyboardAppereance: Bool {
			parent.shouldHandleKeyboardAppereance
		}

		var extraKeyboardSpacing: CGFloat = 25
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

		var keyboardOverlap: CGFloat
		{
			guard
				let tv = tableViewController?.tableView,
				let tvFrameInWindow = tv.superview?.convert(tv.frame, to: nil),
				let intersection = keyboardFrame?.intersection(tvFrameInWindow)
			else { return .zero }
			return intersection.height
		}

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
			tableViewController?.tableView.findFirstResponder != nil
		}

		@objc func keyBoardWillShow(notification: Notification)
		{
			guard shouldHandleKeyboardAppereance else { return }
			guard containsFirstResponder()
			else
			{
				keyboardFrame = nil
				return
			}

			keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

			// Do our own adjustment of contentOffset
			if let tv = tableViewController?.tableView,
				let firstResponder = tv.findFirstResponder()
			{
				let firstResponderFrame = firstResponder.convert(firstResponder.bounds, to: tv)
				let newContentOffset = CGPoint(
					x: tv.contentOffset.x,
					y: tv.adjustedContentInset.top + firstResponderFrame.maxY + keyboardOverlap + extraKeyboardSpacing - tv.frame.height)
				if newContentOffset.y > tv.contentOffset.y
				{
					tv.contentOffset = newContentOffset
				}
			}
		}

		@objc func keyBoardWillHide(notification _: Notification)
		{
			guard shouldHandleKeyboardAppereance else { return }

			keyboardFrame = nil
			tableViewController?.tableView.layoutIfNeeded()
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

@available(iOS 13.0, *)
public enum ASTableViewScrollPosition
{
	case top
	case bottom
	case indexPath(_: IndexPath)
}
