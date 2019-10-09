// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

extension ASCollectionView where SectionID == Int
{
	@inlinable public init<Data, DataID: Hashable, Content: View>(data: [Data], id idKeyPath: KeyPath<Data, DataID>, estimatedItemSize: CGSize? = nil, onCellEvent: ASSectionDataSource<Data, DataID, Content>.OnCellEvent? = nil, layout: Layout = .default, @ViewBuilder content: @escaping ((Data) -> Content))
	{
		self.layout = layout
		sections = [Section(id: 0, data: data, dataID: idKeyPath, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: content)]
	}

	@inlinable public init<Data, Content: View>(data: [Data], estimatedItemSize: CGSize? = nil, onCellEvent: ASSectionDataSource<Data, Data.ID, Content>.OnCellEvent? = nil, layout: Layout = .default, @ViewBuilder content: @escaping ((Data) -> Content)) where Data: Identifiable
	{
		self.layout = layout
		sections = [Section(id: 0, data: data, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: content)]
	}

	init(layout: Layout = .default, @ViewArrayBuilder content: () -> [AnyView])
	{
		self.layout = layout
		sections = [Section(id: 0,
		                    content: content)]
	}
}

public struct ASCollectionView<SectionID: Hashable>: UIViewControllerRepresentable
{
	public typealias Section = ASCollectionViewSection<SectionID>
	public typealias Layout = ASCollectionViewLayout<SectionID>
	public var layout: Layout
	public var sections: [Section]

	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled

	@inlinable public init(layout: Layout = .default, sections: [Section])
	{
		self.layout = layout
		self.sections = sections
	}

	public init(layout: Layout = .default, @SectionArrayBuilder <SectionID> sections: () -> [Section])
	{
		self.layout = layout
		self.sections = sections()
	}

	public func makeUIViewController(context: Context) -> UICollectionViewController
	{
		context.coordinator.parent = self
		let collectionViewLayout = layout.makeLayout(withCoordinator: context.coordinator)

		let collectionViewController = UICollectionViewController(collectionViewLayout: collectionViewLayout)
		updateCollectionViewSettings(collectionViewController.collectionView)

		context.coordinator.collectionViewController = collectionViewController

		context.coordinator.setupDataSource(forCollectionView: collectionViewController.collectionView)
		return collectionViewController
	}

	public func updateUIViewController(_ collectionViewController: UICollectionViewController, context: Context)
	{
		context.coordinator.parent = self
		updateCollectionViewSettings(collectionViewController.collectionView)
		context.coordinator.updateContent(collectionViewController.collectionView, refreshExistingCells: true)
	}

	func updateCollectionViewSettings(_ collectionView: UICollectionView)
	{
		collectionView.backgroundColor = .clear
		collectionView.showsVerticalScrollIndicator = scrollIndicatorsEnabled
		collectionView.showsHorizontalScrollIndicator = scrollIndicatorsEnabled
	}

	public func makeCoordinator() -> Coordinator
	{
		Coordinator(self)
	}

	public class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
	{
		var parent: ASCollectionView
		var collectionViewController: UICollectionViewController?

		var dataSource: UICollectionViewDiffableDataSource<SectionID, ASCollectionViewItemUniqueID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString

		var hostingControllerCache = ASFIFODictionary<ASCollectionViewItemUniqueID, UIViewController>()

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

		func hostingController(forItemID itemID: ASCollectionViewItemUniqueID) -> UIViewController?
		{
			let controller = section(forItemID: itemID)?.hostController(reusingController: hostingControllerCache[itemID], forItemID: itemID)
			hostingControllerCache[itemID] = controller
			return controller
		}

		func setupDataSource(forCollectionView cv: UICollectionView)
		{
			cv.delegate = self
			cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: supplementaryReuseID)
			cv.register(Cell.self, forCellWithReuseIdentifier: cellReuseID)
			dataSource = .init(collectionView: cv)
			{ (collectionView, indexPath, itemID) -> UICollectionViewCell? in
				guard
					let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseID, for: indexPath) as? Cell,
					let hostController = self.hostingController(forItemID: itemID)
				else { return nil }
				cell.invalidateLayout = {
					collectionView.collectionViewLayout.invalidateLayout()
				}
				cell.setupFor(id: itemID,
				              hostingController: hostController)
				return cell
			}
			dataSource?.supplementaryViewProvider = { (cv, kind, indexPath) -> UICollectionReusableView? in
				guard
					let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
				else { return nil }

				let headerView = self.parent.sections[indexPath.section].header
				reusableView.setupFor(id: indexPath.section,
				                      view: headerView)
				return reusableView
			}
			populateDataSource()
			setupPrefetching()
		}

		func populateDataSource()
		{
			var snapshot = NSDiffableDataSourceSnapshot<SectionID, ASCollectionViewItemUniqueID>()
			snapshot.appendSections(parent.sections.map { $0.id })
			parent.sections.forEach
			{
				snapshot.appendItems($0.itemIDs, toSection: $0.id)
			}
			dataSource?.apply(snapshot)
		}

		func updateContent(_ cv: UICollectionView, refreshExistingCells: Bool)
		{
			if refreshExistingCells
			{
				cv.visibleCells.forEach
				{ cell in
					guard
						let cell = cell as? Cell,
						let itemID = cell.id,
						let hostController = self.hostingController(forItemID: itemID)
					else { return }
					cell.update(hostController)
				}
				cv.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader).forEach
				{
					guard let header = parent.sections[$0.section].header else { return }
					(cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: $0) as? ASCollectionViewSupplementaryView)?
						.updateView(header)
				}
			}
			populateDataSource()
		}

		public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.willAppear(in: collectionViewController)
			currentlyPrefetching.remove(indexPath)
			parent.sections[indexPath.section].onAppear(indexPath)
			queuePrefetch.send()
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			parent.sections[indexPath.section].onDisappear(indexPath)
		}

		public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
		{
			(view as? ASCollectionViewSupplementaryView)?.willAppear(in: collectionViewController)
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
		{
			(view as? ASCollectionViewSupplementaryView)?.didDisappear()
		}

		private let queuePrefetch = PassthroughSubject<Void, Never>()
		private var prefetchSubscription: AnyCancellable?
		private var currentlyPrefetching: Set<IndexPath> = []

		func setupPrefetching()
		{
			prefetchSubscription = queuePrefetch
				.collect(.byTime(DispatchQueue.main, 0.1)) // Wanted to use .throttle(for: 0.1, scheduler: DispatchQueue(label: "TEST"), latest: true) -> THIS CRASHES?? BUG??
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
					let sectionIndexPaths = self.parent.sections[item.section].getIndexPaths(withSectionIndex: item.section)
					let nextItemsInSection = sectionIndexPaths.suffix(from: item.last).dropFirst().prefix(5)
					let previousItemsInSection = sectionIndexPaths.prefix(upTo: item.first).suffix(5)
					return Array(nextItemsInSection) + Array(previousItemsInSection)
				}
				// CHECK IF THERES AN EARLIER SECTION TO PRELOAD
				if
					let firstSection = toPrefetch.keys.min(), // FIND THE EARLIEST VISIBLE SECTION
					(firstSection - 1) >= self.parent.sections.startIndex, // CHECK THERE IS A SECTION BEFORE THIS
					let firstIndex = visibleIndexPathsBySection[firstSection]?.first, firstIndex < 5 // CHECK HOW CLOSE TO THIS SECTION WE ARE
				{
					let precedingSection = firstSection - 1
					toPrefetch[precedingSection] = self.parent.sections[precedingSection].getIndexPaths(withSectionIndex: precedingSection).suffix(5)
				}
				// CHECK IF THERES A LATER SECTION TO PRELOAD
				if
					let lastSection = toPrefetch.keys.max(), // FIND THE EARLIEST VISIBLE SECTION
					(lastSection + 1) < self.parent.sections.endIndex, // CHECK THERE IS A SECTION BEFORE THIS
					let lastIndex = visibleIndexPathsBySection[lastSection]?.last,
					let lastSectionEndIndex = self.parent.sections[lastSection].getIndexPaths(withSectionIndex: lastSection).last?.item,
					(lastSectionEndIndex - lastIndex) < 5 // CHECK HOW CLOSE TO THIS SECTION WE ARE
				{
					let nextSection = lastSection + 1
					toPrefetch[nextSection] = Array(self.parent.sections[nextSection].getIndexPaths(withSectionIndex: nextSection).prefix(5))
				}
				return toPrefetch
			}
			.sink
			{ prefetch in
				prefetch.forEach
				{ sectionIndex, toPrefetch in
					if !toPrefetch.isEmpty
					{
						self.parent.sections[sectionIndex].prefetch(toPrefetch)
					}
					let toCancel = Array(self.currentlyPrefetching.filter { $0.section == sectionIndex }.subtracting(toPrefetch))
					if !toCancel.isEmpty
					{
						self.parent.sections[sectionIndex].cancelPrefetch(toCancel)
					}
				}

				self.currentlyPrefetching = Set(prefetch.flatMap { $0.value })
			}
		}

		/*
		 //DISABLED AS PREFETCH API WAS NOT WORKING FOR COMPOSITIONAL LAYOUT
		  public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		  print("PREFETCH \(indexPaths)")
		 /* let itemIDsToPrefetchBySection: [Int: [ASCollectionViewItemUniqueID]] = indexPaths.reduce(into: [:]) { (result, indexPath) in
		         guard let itemID = dataSource?.itemIdentifier(for: indexPath) else { return }
		         if result[indexPath.section] == nil {
		             result[indexPath.section] = [itemID]
		         } else {
		             result[indexPath.section]?.append(itemID)
		         }
		     }
		     itemIDsToPrefetchBySection.forEach {
		         parent.sections[$0.key].onCellEvent($0.value)
		     } */
		  }

		  public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		  print("CANCEL PREFETCH \(indexPaths)")
		  }*/
	}
}
