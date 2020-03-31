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

	// MARK: Key variables

	public var sections: [Section]
	public var style: UITableView.Style

	// MARK: Environment variables

	@Environment(\.tableViewSeparatorsEnabled) private var separatorsEnabled
	@Environment(\.onPullToRefresh) private var onPullToRefresh
	@Environment(\.tableViewOnReachedBottom) private var onReachedBottom
	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled
	@Environment(\.contentInsets) private var contentInsets
	@Environment(\.alwaysBounceVertical) private var alwaysBounceVertical
	@Environment(\.editMode) private var editMode
	@Environment(\.animateOnDataRefresh) private var animateOnDataRefresh

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

		updateTableViewSettings(tableViewController.tableView)
		context.coordinator.tableViewController = tableViewController

		context.coordinator.setupDataSource(forTableView: tableViewController.tableView)
		return tableViewController
	}

	public func updateUIViewController(_ tableViewController: AS_TableViewController, context: Context)
	{
		context.coordinator.parent = self
		updateTableViewSettings(tableViewController.tableView)
		context.coordinator.updateContent(tableViewController.tableView, transaction: context.transaction, refreshExistingCells: true)
		context.coordinator.configureRefreshControl(for: tableViewController.tableView)
	}

	func updateTableViewSettings(_ tableView: UITableView)
	{
		assignIfChanged(tableView, \.backgroundColor, newValue: (style == .plain) ? .clear : .systemGroupedBackground)
		assignIfChanged(tableView, \.separatorStyle, newValue: separatorsEnabled ? .singleLine : .none)
		assignIfChanged(tableView, \.contentInset, newValue: contentInsets)
		assignIfChanged(tableView, \.alwaysBounceVertical, newValue: alwaysBounceVertical)
		assignIfChanged(tableView, \.showsVerticalScrollIndicator, newValue: scrollIndicatorsEnabled)
		assignIfChanged(tableView, \.showsHorizontalScrollIndicator, newValue: scrollIndicatorsEnabled)

		let isEditing = editMode?.wrappedValue.isEditing ?? false
		assignIfChanged(tableView, \.allowsSelection, newValue: isEditing)
		assignIfChanged(tableView, \.allowsMultipleSelection, newValue: isEditing)
	}

	public func makeCoordinator() -> Coordinator
	{
		Coordinator(self)
	}

	public class Coordinator: NSObject, ASTableViewCoordinator, UITableViewDelegate, UITableViewDataSourcePrefetching
	{
		var parent: ASTableView
		weak var tableViewController: AS_TableViewController?

		var dataSource: ASTableViewDiffableDataSource<SectionID, ASCollectionViewItemUniqueID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString

		// MARK: Private tracking variables

		private var hasDoneInitialSetup = false
		private var lastSnapshot: NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>?

		// MARK: Caching

		private var visibleHostingControllers: [ASCollectionViewItemUniqueID: ASHostingControllerProtocol] = [:]
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

		func setupDataSource(forTableView tv: UITableView)
		{
			tv.delegate = self
			tv.prefetchDataSource = self
			tv.register(Cell.self, forCellReuseIdentifier: cellReuseID)
			tv.register(ASTableViewSupplementaryView.self, forHeaderFooterViewReuseIdentifier: supplementaryReuseID)

			dataSource = .init(tableView: tv)
			{ [weak self] (tableView, indexPath, itemID) -> UITableViewCell? in
				guard let self = self else { return nil }
				guard
					let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseID, for: indexPath) as? Cell
				else { return nil }

				guard let section = self.parent.sections[safe: indexPath.section] else { return cell }

				cell.backgroundColor = (self.parent.style == .plain) ? .clear : .secondarySystemGroupedBackground

				// Cell layout invalidation callback
				cell.invalidateLayout = { [weak self] in
					self?.reloadRow(indexPath)
				}

				// Self Sizing Settings
				let selfSizingContext = ASSelfSizingContext(cellType: .content, indexPath: indexPath)
				cell.selfSizingConfig =
					section.dataSource.getSelfSizingSettings(context: selfSizingContext)
						?? ASSelfSizingConfig(selfSizeHorizontally: false, selfSizeVertically: true)

				// Set itemID
				cell.itemID = itemID

				// Update hostingController
				let cachedHC = self.explicitlyCachedHostingControllers[itemID] ?? self.visibleHostingControllers[itemID] ?? self.autoCachingHostingControllers[itemID]
				cell.hostingController = section.dataSource.updateOrCreateHostController(forItemID: itemID, existingHC: cachedHC)

				// Cache the HC
				self.autoCachingHostingControllers[itemID] = cell.hostingController
				self.visibleHostingControllers[itemID] = cell.hostingController
				if section.shouldCacheCells
				{
					self.explicitlyCachedHostingControllers[itemID] = cell.hostingController
				}

				return cell
			}
			dataSource?.defaultRowAnimation = .fade
		}

		func populateDataSource(animated: Bool = true)
		{
			var snapshot = NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>()
			snapshot.appendSections(parent.sections.map { $0.id })
			parent.sections.forEach
			{
				snapshot.appendItems($0.itemIDs, toSection: $0.id)
			}
			lastSnapshot = snapshot
			dataSource?.apply(snapshot, animatingDifferences: animated)
			{
				self.tableViewController.map { self.didUpdateContentSize($0.tableView.contentSize) }
			}
		}

		func updateContent(_ tv: UITableView, transaction: Transaction?, refreshExistingCells: Bool)
		{
			guard hasDoneInitialSetup else { return }
			if refreshExistingCells
			{
				withAnimation(parent.animateOnDataRefresh ? transaction?.animation : nil) {
					self.visibleHostingControllers.forEach { itemID, hc in
						self.section(forItemID: itemID)?.dataSource.update(hc, forItemID: itemID)
					}
				}
			}
			let transactionAnimationEnabled = (transaction?.animation != nil) && !(transaction?.disablesAnimations ?? false)
			populateDataSource(animated: parent.animateOnDataRefresh && transactionAnimationEnabled)
			updateSelectionBindings(tv)
		}

		func reloadRow(_ indexPath: IndexPath)
		{
			guard
				let itemID = itemID(for: indexPath),
				var snapshot = lastSnapshot
			else { return }
			snapshot.reloadItems([itemID])
			dataSource?.apply(snapshot, animatingDifferences: true)
			{
				self.tableViewController.map { self.didUpdateContentSize($0.tableView.contentSize) }
			}
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

		public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
		{
			parent.sections[safe: indexPath.section]?.estimatedRowHeight ?? 50
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
			(cell as? Cell)?.itemID.map { visibleHostingControllers[$0] = nil }
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
			let selectedSafe = selected.filter { parent.sections.containsIndex($0.section) }
			Dictionary(grouping: selectedSafe) { $0.section }
				.mapValues
			{
				Set($0.map { $0.item })
			}
			.forEach { sectionID, indices in
				parent.sections[safe: sectionID]?.dataSource.updateSelection(indices)
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
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: supplementaryReuseID) as? ASTableViewSupplementaryView
			else { return nil }
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
			return reusableView
		}

		public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: supplementaryReuseID) as? ASTableViewSupplementaryView
			else { return nil }
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
			return reusableView
		}

		public func scrollViewDidScroll(_ scrollView: UIScrollView)
		{
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
					parent.onReachedBottom()
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

@available(iOS 13.0, *)
class ASTableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable
{
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
	{
		true
	}

	override func apply(_ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil)
	{
		if animatingDifferences
		{
			super.apply(snapshot, animatingDifferences: true, completion: completion)
		}
		else
		{
			UIView.performWithoutAnimation {
				super.apply(snapshot, animatingDifferences: true, completion: completion) // Animation must be true to get diffing. However we have disabled animation using .performWithoutAnimation
			}
		}
	}
}
