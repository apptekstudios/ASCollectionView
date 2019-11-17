// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

extension ASTableView where SectionID == Int
{
	/**
	 Initializes a  table view with a single section.

	 - Parameters:
	 - section: A single section (ASTableViewSection)
	 */
	public init(style: UITableView.Style = .plain, selectedItems: Binding<IndexSet>? = nil, section: Section)
	{
		self.style = style
		self.selectedItems = selectedItems.map
		{ selectedItems in
			Binding(
				get: { [:] },
				set: { selectedItems.wrappedValue = $0.first?.value ?? [] })
		}
		sections = [section]
	}

	/**
	 Initializes a  table view with a single section.
	 */
	public init<Data, DataID: Hashable, Content: View>(
		style: UITableView.Style = .plain,
		data: [Data],
		dataID dataIDKeyPath: KeyPath<Data, DataID>,
		selectedItems: Binding<IndexSet>? = nil,
		@ViewBuilder contentBuilder: @escaping ((Data, CellContext) -> Content))
	{
		self.style = style
		let section = ASTableViewSection(
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
	 Initializes a  table view with a single section of static content
	 */
	init(@ViewArrayBuilder staticContent: () -> [AnyView]) // Clashing with above functions in Swift 5.1, therefore internal for time being
	{
		style = .plain
		sections = [
			ASTableViewSection(id: 0, content: staticContent)
		]
	}
}

public typealias ASTableViewSection<SectionID: Hashable> = ASCollectionViewSection<SectionID>

public struct ASTableView<SectionID: Hashable>: UIViewControllerRepresentable
{
	public typealias Section = ASTableViewSection<SectionID>
	public var sections: [Section]
	public var style: UITableView.Style
	public var selectedItems: Binding<[SectionID: IndexSet]>?

	@Environment(\.tableViewSeparatorsEnabled) private var separatorsEnabled
	@Environment(\.tableViewOnReachedBottom) private var onReachedBottom
	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled
	@Environment(\.contentInsets) private var contentInsets
	@Environment(\.alwaysBounceVertical) private var alwaysBounceVertical
	@Environment(\.editMode) private var editMode

	/**
	 Initializes a  table view with the given sections

	 - Parameters:
	 - sections: An array of sections (ASTableViewSection)
	 */
	@inlinable public init(style: UITableView.Style = .plain, selectedItems: Binding<[SectionID: IndexSet]>? = nil, sections: [Section])
	{
		self.style = style
		self.selectedItems = selectedItems
		self.sections = sections
	}

	@inlinable public init(style: UITableView.Style = .plain, selectedItems: Binding<[SectionID: IndexSet]>? = nil, @SectionArrayBuilder <SectionID> sectionBuilder: () -> [Section])
	{
		self.style = style
		self.selectedItems = selectedItems
		sections = sectionBuilder()
	}

	public func makeUIViewController(context: Context) -> UITableViewController
	{
		context.coordinator.parent = self

		let tableViewController = UITableViewController(style: style)
		tableViewController.tableView.tableFooterView = UIView()
		updateTableViewSettings(tableViewController.tableView)
		context.coordinator.tableViewController = tableViewController

		context.coordinator.setupDataSource(forTableView: tableViewController.tableView)
		return tableViewController
	}

	public func updateUIViewController(_ tableViewController: UITableViewController, context: Context)
	{
		context.coordinator.parent = self
		updateTableViewSettings(tableViewController.tableView)
		context.coordinator.updateContent(tableViewController.tableView, refreshExistingCells: false)
	}

	func updateTableViewSettings(_ tableView: UITableView)
	{
		tableView.backgroundColor = .clear
		tableView.separatorStyle = separatorsEnabled ? .singleLine : .none
		tableView.contentInset = contentInsets
		tableView.alwaysBounceVertical = alwaysBounceVertical
		tableView.showsVerticalScrollIndicator = scrollIndicatorsEnabled
		tableView.showsHorizontalScrollIndicator = scrollIndicatorsEnabled

		let isEditing = editMode?.wrappedValue.isEditing ?? false
		tableView.allowsSelection = isEditing
		tableView.allowsMultipleSelection = isEditing
	}

	public func makeCoordinator() -> Coordinator
	{
		Coordinator(self)
	}

	public class Coordinator: NSObject, UITableViewDelegate, UITableViewDataSourcePrefetching
	{
		var parent: ASTableView
		var tableViewController: UITableViewController?

		var dataSource: UITableViewDiffableDataSource<SectionID, ASCollectionViewItemUniqueID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString

		var hostingControllerCache = ASFIFODictionary<ASCollectionViewItemUniqueID, ASHostingControllerProtocol>()

		typealias Cell = ASTableViewCell

		init(_ parent: ASTableView)
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

		@discardableResult
		func configureHostingController(forItemID itemID: ASCollectionViewItemUniqueID, isSelected: Bool) -> ASHostingControllerProtocol?
		{
			let controller = section(forItemID: itemID)?.dataSource.configureHostingController(reusingController: hostingControllerCache[itemID], forItemID: itemID, isSelected: isSelected)
			hostingControllerCache[itemID] = controller
			return controller
		}

		func setupDataSource(forTableView tv: UITableView)
		{
			tv.delegate = self
			tv.prefetchDataSource = self
			tv.register(Cell.self, forCellReuseIdentifier: cellReuseID)
			tv.register(ASTableViewSupplementaryView.self, forHeaderFooterViewReuseIdentifier: supplementaryReuseID)

			dataSource = .init(tableView: tv)
			{ (tableView, indexPath, itemID) -> UITableViewCell? in
				let isSelected = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
				guard
					let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseID, for: indexPath) as? Cell,
					let hostController = self.configureHostingController(forItemID: itemID, isSelected: isSelected)
				else { return nil }
				cell.invalidateLayout = {
					tv.beginUpdates()
					tv.endUpdates()
				}
				cell.setupFor(
					id: itemID,
					hostingController: hostController)
				return cell
			}
			dataSource?.defaultRowAnimation = .fade
			/* self.dataSource?. = { (cv, kind, indexPath) -> UICollectionReusableView? in
			     guard
			         let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
			         else { return nil }

			     let headerView = self.parent.sections[indexPath.section].header
			     reusableView.setupFor(id: indexPath.section,
			                           view: headerView)
			     return reusableView
			 } */
		}

		func updateContent(_ tv: UITableView, refreshExistingCells: Bool)
		{
			var snapshot = NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>()
			snapshot.appendSections(parent.sections.map { $0.id })
			parent.sections.forEach
			{
				snapshot.appendItems($0.itemIDs, toSection: $0.id)
			}
			if refreshExistingCells
			{
				tv.visibleCells.forEach
				{ cell in
					guard
						let cell = cell as? Cell,
						let itemID = cell.id
					else { return }

					self.configureHostingController(forItemID: itemID, isSelected: cell.isSelected)
				}
				/* tv.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader).forEach {
				     guard let header = parent.sections[$0.section].header else { return }
				     (cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: $0) as? ASCollectionViewSupplementaryView)?
				         .updateView(header)
				 } */
			}
			// APPLY CHANGES (ADD/REMOVE CELLS) AFTER REFRESHING CELLS
			dataSource?.apply(snapshot, animatingDifferences: refreshExistingCells)
			updateSelectionBindings(tv)

			DispatchQueue.main.async
			{
				self.checkIfReachedBottom(tv)
			}
		}

		public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
		{
			parent.sections[indexPath.section].estimatedRowHeight ?? 50
		}

		public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			(cell as? Cell)?.willAppear(in: tableViewController)
			parent.sections[indexPath.section].dataSource.onAppear(indexPath)
		}

		public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			parent.sections[indexPath.section].dataSource.onDisappear(indexPath)
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
				parent.sections[$0.key].dataSource.prefetch($0.value)
			}
		}

		public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath])
		{
			let itemIDsToCancelPrefetchBySection: [Int: [IndexPath]] = Dictionary(grouping: indexPaths) { $0.section }
			itemIDsToCancelPrefetchBySection.forEach
			{
				parent.sections[$0.key].dataSource.cancelPrefetch($0.value)
			}
		}

		public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
		{
			guard
				let cell = tableView.cellForRow(at: indexPath) as? Cell,
				let itemID = cell.id
			else { return }
			updateSelectionBindings(tableView)
			configureHostingController(forItemID: itemID, isSelected: true)
		}

		public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
		{
			guard
				let cell = tableView.cellForRow(at: indexPath) as? Cell,
				let itemID = cell.id
			else { return }
			updateSelectionBindings(tableView)
			configureHostingController(forItemID: itemID, isSelected: false)
		}

		func updateSelectionBindings(_ tableView: UITableView)
		{
			guard let selectedItemsBinding = parent.selectedItems else { return }
			let selected = tableView.indexPathsForSelectedRows ?? []
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

		public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
		{
			guard parent.sections[section].supplementary(ofKind: UICollectionView.elementKindSectionHeader) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return parent.sections[section].estimatedHeaderHeight ?? 50
		}

		public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
		{
			guard parent.sections[section].supplementary(ofKind: UICollectionView.elementKindSectionHeader) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return UITableView.automaticDimension
		}

		public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
		{
			guard parent.sections[section].supplementary(ofKind: UICollectionView.elementKindSectionFooter) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return parent.sections[section].estimatedFooterHeight ?? 50
		}

		public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
		{
			guard parent.sections[section].supplementary(ofKind: UICollectionView.elementKindSectionFooter) != nil else
			{
				return CGFloat.leastNormalMagnitude
			}
			return UITableView.automaticDimension
		}

		public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.supplementaryReuseID) as? ASTableViewSupplementaryView
			else { return nil }
			if let supplementaryView = self.parent.sections[section].supplementary(ofKind: UICollectionView.elementKindSectionHeader)
			{
				reusableView.setupFor(
					id: section,
					view: supplementaryView)
			}
			return reusableView
		}

		public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
		{
			guard let reusableView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.supplementaryReuseID) as? ASTableViewSupplementaryView
			else { return nil }
			if let supplementaryView = self.parent.sections[section].supplementary(ofKind: UICollectionView.elementKindSectionFooter)
			{
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

/*
 class ASTableViewDataSource<SectionIdentifierType, ItemIdentifierType>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
 public typealias HeaderFooterViewProvider = (_ sectionIndex: Int) -> UITableViewHeaderFooterView?

 public var headerViewProvider: HeaderFooterViewProvider?
 public var footerViewProvider: HeaderFooterViewProvider?

 func headerView(forSection section: Int) -> UITableViewHeaderFooterView? {
 	headerViewProvider?(section)
 }

 func footerView(forSection section: Int) -> UITableViewHeaderFooterView? {
 	footerViewProvider?(section)
 }
 }
 */
