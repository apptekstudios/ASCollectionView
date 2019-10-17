// ASCollectionView. Created by Apptek Studios 2019

import Combine
import SwiftUI

extension ASCollectionView where SectionID == Int
{
	/**
	Initializes a  collection view with a single section.
	
	- Parameters:
		- data: The data to display in the collection view
		- id: The keypath to a hashable identifier of each data item
		- estimatedItemSize: (Optional) Provide an estimated item size to aid in calculating the layout
		- onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
		- layout: The layout to use for the collection view
		- content: A closure returning a SwiftUI view for the given data item
	*/
	@inlinable public init<Data, DataID: Hashable, Content: View>(data: [Data], id idKeyPath: KeyPath<Data, DataID>, estimatedItemSize: CGSize? = nil, onCellEvent: OnCellEvent<Data>? = nil, layout: Layout = .default, @ViewBuilder content: @escaping ((Data) -> Content))
	{
		self.layout = layout
		sections = [Section(id: 0, data: data, dataID: idKeyPath, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: content)]
	}
	
	/**
	Initializes a  collection view with a single section.
	
	- Parameters:
		- data: The data to display in the collection view. This initialiser expects data that conforms to 'Identifiable'
		- estimatedItemSize: (Optional) Provide an estimated item size to aid in calculating the layout
		- onCellEvent: Use this to respond to cell appearance/disappearance, and preloading events.
		- layout: The layout to use for the collection view
		- content: A closure returning a SwiftUI view for the given data item
	*/
	@inlinable public init<Data, Content: View>(data: [Data], estimatedItemSize: CGSize? = nil, onCellEvent: OnCellEvent<Data>? = nil, layout: Layout = .default, @ViewBuilder content: @escaping ((Data) -> Content)) where Data: Identifiable
	{
		self.layout = layout
		sections = [Section(id: 0, data: data, estimatedItemSize: estimatedItemSize, onCellEvent: onCellEvent, contentBuilder: content)]
	}
	
	/**
	Initializes a  collection view with a single section and static content.
	
	- Parameters:
		- layout: The layout to use for the collection view
		- content: A closure returning a number of SwiftUI views to display in the collection view
	*/
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

	/**
	Initializes a  collection view with the given sections
	
	- Parameters:
		- layout: The layout to use for the collection view
		- sections: An array of sections (ASSection)
	*/
	@inlinable public init(layout: Layout = .default, sections: [Section])
	{
		self.layout = layout
		self.sections = sections
	}
	
	/**
	Initializes a  collection view with the given sections
	
	- Parameters:
		- layout: The layout to use for the collection view
		- sections: A closure providing sections to display in the collection view (ASSection)
	*/
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
        let supplementaryEmptyKind = UUID().uuidString //Used to prevent crash if supplementaries defined in layout but not provided by the section

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
		
		func supplementaryKinds() -> Set<String> {
			parent.sections.reduce(into: Set<String>()) { result, section in result.formUnion(section.supplementaryKinds) }
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
			cv.register(Cell.self, forCellWithReuseIdentifier: cellReuseID)
            cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: supplementaryEmptyKind, withReuseIdentifier: supplementaryReuseID) //Used to prevent crash if supplementaries defined in layout but not provided by the section
			supplementaryKinds().forEach { kind in
				cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryReuseID)
			}
			
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
                guard self.supplementaryKinds().contains(kind) else {
                    let emptyView = cv.dequeueReusableSupplementaryView(ofKind: self.supplementaryEmptyKind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
                    emptyView?.setupFor(id: indexPath.section, view: nil)
                    return emptyView
                }
				guard let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
                    else { return nil }
				let supplementaryView = self.parent.sections[indexPath.section].supplementary(ofKind: kind)
				reusableView.setupFor(id: indexPath.section,
				                      view: supplementaryView)
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
				
				supplementaryKinds().forEach { kind in
					cv.indexPathsForVisibleSupplementaryElements(ofKind: kind).forEach
						{
							guard let supplementaryView = parent.sections[$0.section].supplementary(ofKind: kind) else { return }
							(cv.supplementaryView(forElementKind: kind, at: $0) as? ASCollectionViewSupplementaryView)?
								.updateView(supplementaryView)
					}
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


		/*
		 //REPLACED WITH CUSTOM PREFETCH SOLUTION AS PREFETCH API WAS NOT WORKING FOR COMPOSITIONAL LAYOUT
		  public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])
		  public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath])
        */
	}
}

extension ASCollectionView.Coordinator {
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
}
