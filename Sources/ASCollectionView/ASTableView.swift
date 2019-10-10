// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

/* extension ASTableView where SectionID == Int {
 @inlinable public init<Data, DataID: Hashable, Content: View>(data: [Data], id idKeyPath: KeyPath<Data, DataID>, onCellEvent: ASTableViewSectionDataSource<Data, DataID, Content>.OnCellEvent? = nil, mode: UITableView.Style = .plain, @ViewBuilder content: @escaping ((Data) -> Content)) {
 self.mode = mode
 self.sections = [Section(id: 0, data: data, dataID: idKeyPath, onCellEvent: onCellEvent, contentBuilder: content)]
 }

 @inlinable init<Data, Content: View>(data: [Data], onCellEvent: ASTableViewSectionDataSource<Data, Data.ID, Content>.OnCellEvent? = nil, mode: UITableView.Style = .plain, @ViewBuilder content: @escaping ((Data) -> Content)) where Data: Identifiable {
 self.mode = mode
 self.sections = [Section(id: 0, data: data, onCellEvent: onCellEvent, contentBuilder: content)]
 }

 init(mode: UITableView.Style = .plain, @ViewArrayBuilder content: (() -> [AnyView])) {
 self.mode = mode
 self.sections = [
 Section(id: 0,
 content: content)
 ]
 }
 } */
public typealias ASTableViewSection<SectionID: Hashable> = ASCollectionViewSection<SectionID>

public struct ASTableView<SectionID: Hashable>: UIViewControllerRepresentable
{
	public typealias Section = ASTableViewSection<SectionID>
	public var sections: [Section]
	public var mode: UITableView.Style

	@Environment(\.tableViewSeparatorsEnabled) private var separatorsEnabled
	@Environment(\.tableViewOnReachedBottom) private var onReachedBottom
	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled

	@inlinable public init(mode: UITableView.Style = .plain, sections: [Section])
	{
		self.mode = mode
		self.sections = sections
	}

	@inlinable public init(mode: UITableView.Style = .plain, @SectionArrayBuilder <SectionID> sections: () -> [Section])
	{
		self.mode = mode
		self.sections = sections()
	}

	public func makeUIViewController(context: Context) -> UITableViewController
	{
		context.coordinator.parent = self

		let tableViewController = UITableViewController(style: .plain)
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
		context.coordinator.updateContent(tableViewController.tableView, refreshExistingCells: true)
	}

	func updateTableViewSettings(_ tableView: UITableView)
	{
		tableView.backgroundColor = .clear
		tableView.separatorStyle = separatorsEnabled ? .singleLine : .none
		tableView.showsVerticalScrollIndicator = scrollIndicatorsEnabled
		tableView.showsHorizontalScrollIndicator = scrollIndicatorsEnabled
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

		var hostingControllerCache = ASFIFODictionary<ASCollectionViewItemUniqueID, UIViewController>()

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

		func hostingController(forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
		{
			let controller = section(forItemID: itemID)?.hostController(reusingController: hostingControllerCache[itemID], forItemID: itemID)
			hostingControllerCache[itemID] = controller
			return controller
		}

		func setupDataSource(forTableView tv: UITableView)
		{
			tv.delegate = self
			tv.prefetchDataSource = self
			tv.register(ASTableViewSupplementaryView.self, forHeaderFooterViewReuseIdentifier: supplementaryReuseID)
			tv.register(Cell.self, forCellReuseIdentifier: cellReuseID)
			dataSource = .init(tableView: tv)
			{ (tableView, indexPath, itemID) -> UITableViewCell? in
				guard
					let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseID, for: indexPath) as? Cell,
					let hostController = self.hostingController(forItemID: itemID)
				else { return nil }
				cell.invalidateLayout = {
					tv.beginUpdates()
					tv.endUpdates()
				}
				cell.setupFor(id: itemID,
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

			updateContent(tv, refreshExistingCells: false)
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
						let itemID = cell.id,
						let hostController = self.hostingController(forItemID: itemID)
					else { return }
					cell.update(hostController)
				}
				/* tv.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader).forEach {
				     guard let header = parent.sections[$0.section].header else { return }
				     (cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: $0) as? ASCollectionViewSupplementaryView)?
				         .updateView(header)
				 } */
			}
			// APPLY CHANGES (ADD/REMOVE CELLS) AFTER REFRESHING CELLS
			dataSource?.apply(snapshot, animatingDifferences: refreshExistingCells)

			DispatchQueue.main.async
			{
				self.checkIfReachedBottom(tv)
			}
		}

		public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
		{
			parent.sections[indexPath.section].estimatedItemSize?.height ?? 50
		}

		public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			(cell as? Cell)?.willAppear(in: tableViewController)
			parent.sections[indexPath.section].onAppear(indexPath)
		}

		public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			parent.sections[indexPath.section].onDisappear(indexPath)
		}

		public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
		{
			(view as? ASTableViewSupplementaryView)?.willAppear(in: tableViewController)
		}

		public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int)
		{
			(view as? ASTableViewSupplementaryView)?.didDisappear()
		}

		public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath])
		{
			let itemIDsToPrefetchBySection: [Int: [IndexPath]] = Dictionary(grouping: indexPaths) { $0.section }
			itemIDsToPrefetchBySection.forEach
			{
				parent.sections[$0.key].prefetch($0.value)
			}
		}

		public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath])
		{
			let itemIDsToCancelPrefetchBySection: [Int: [IndexPath]] = Dictionary(grouping: indexPaths) { $0.section }
			itemIDsToCancelPrefetchBySection.forEach
			{
				parent.sections[$0.key].cancelPrefetch($0.value)
			}
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
