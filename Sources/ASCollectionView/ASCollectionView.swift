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
    
    var delegateInitialiser: (() -> ASCollectionViewDelegate) = ASCollectionViewDelegate.init

	@Environment(\.scrollIndicatorsEnabled) private var scrollIndicatorsEnabled
	@Environment(\.contentInsets) private var contentInsets

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
		collectionView.showsVerticalScrollIndicator = scrollIndicatorsEnabled
		collectionView.showsHorizontalScrollIndicator = scrollIndicatorsEnabled
	}

	public func makeCoordinator() -> Coordinator
	{
		Coordinator(self)
	}

    public class Coordinator: ASCollectionViewCoordinator
	{
		var parent: ASCollectionView
        var delegate: ASCollectionViewDelegate?
        
		var collectionViewController: AS_CollectionViewController?

		var dataSource: UICollectionViewDiffableDataSource<SectionID, ASCollectionViewItemUniqueID>?

		let cellReuseID = UUID().uuidString
		let supplementaryReuseID = UUID().uuidString
        let supplementaryEmptyKind = UUID().uuidString //Used to prevent crash if supplementaries defined in layout but not provided by the section

		var hostingControllerCache = ASFIFODictionary<ASCollectionViewItemUniqueID, ASHostingControllerProtocol>()

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

		@discardableResult
		func configureHostingController(forItemID itemID: ASCollectionViewItemUniqueID) -> ASHostingControllerProtocol?
		{
			let controller = section(forItemID: itemID)?.configureHostingController(reusingController: hostingControllerCache[itemID], forItemID: itemID)
			hostingControllerCache[itemID] = controller
			return controller
		}

		func setupDataSource(forCollectionView cv: UICollectionView)
		{
			cv.register(Cell.self, forCellWithReuseIdentifier: cellReuseID)
            cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: supplementaryEmptyKind, withReuseIdentifier: supplementaryReuseID) //Used to prevent crash if supplementaries defined in layout but not provided by the section
			supplementaryKinds().forEach { kind in
				cv.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: supplementaryReuseID)
			}
			
			dataSource = .init(collectionView: cv)
			{ (collectionView, indexPath, itemID) -> UICollectionViewCell? in
				guard
					let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellReuseID, for: indexPath) as? Cell
					else { return nil }
				guard let hostController = self.configureHostingController(forItemID: itemID)
					else { return cell }
				cell.invalidateLayout = {
					collectionView.collectionViewLayout.invalidateLayout()
				}
                cell.selfSizeHorizontal = self.delegate?.collectionView(cellShouldSelfSizeHorizontallyForItemAt: indexPath) ?? true
                cell.selfSizeVertical = self.delegate?.collectionView(cellShouldSelfSizeVerticallyForItemAt: indexPath) ?? true
				cell.setupFor(id: itemID,
				              hostingController: hostController)
				return cell
			}
			dataSource?.supplementaryViewProvider = { (cv, kind, indexPath) -> UICollectionReusableView? in
                guard self.supplementaryKinds().contains(kind) else {
                    let emptyView = cv.dequeueReusableSupplementaryView(ofKind: self.supplementaryEmptyKind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
                    return emptyView
                }
				guard let reusableView = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.supplementaryReuseID, for: indexPath) as? ASCollectionViewSupplementaryView
                    else { return nil }
				if let supplementaryView = self.parent.sections[indexPath.section].supplementary(ofKind: kind) {
					reusableView.setupFor(id: indexPath.section,
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
		}

		func updateContent(_ cv: UICollectionView, animated: Bool, refreshExistingCells: Bool)
		{
			if refreshExistingCells && collectionViewController?.parent != nil
			{
				cv.visibleCells.forEach
				{ cell in
					guard
						let cell = cell as? Cell,
						let itemID = cell.id
					else { return }
					self.configureHostingController(forItemID: itemID)
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
			populateDataSource(animated: collectionViewController?.parent != nil)
		}

		public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.willAppear(in: collectionViewController)
			currentlyPrefetching.remove(indexPath)
            guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].onAppear(indexPath)
			queuePrefetch.send()
		}

		public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
		{
			(cell as? Cell)?.didDisappear()
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
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
		
		func dragItem(for indexPath: IndexPath) -> UIDragItem? {
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return nil }
			return parent.sections[indexPath.section].dataSource.getDragItem(for: indexPath)
		}
		
		func canDrop(at indexPath: IndexPath) -> Bool {
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return false }
			return parent.sections[indexPath.section].dataSource.dropEnabled
		}
		
		func removeItem(from indexPath: IndexPath) {
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].dataSource.removeItem(from: indexPath)
		}
		
		func insertItems(_ items: [UIDragItem], at indexPath: IndexPath) {
			guard !indexPath.isEmpty, indexPath.section < parent.sections.endIndex else { return }
			parent.sections[indexPath.section].dataSource.insertDragItems(items, at: indexPath)
		}

		private let queuePrefetch = PassthroughSubject<Void, Never>()
		private var prefetchSubscription: AnyCancellable?
		private var currentlyPrefetching: Set<IndexPath> = []

	}
}

public extension ASCollectionView {
    func customDelegate(_ delegateInitialiser: @escaping (() -> ASCollectionViewDelegate)) -> Self {
        var cv = self
        cv.delegateInitialiser = delegateInitialiser
        return cv
    }
}

internal protocol ASCollectionViewCoordinator: class {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
	func dragItem(for indexPath: IndexPath) -> UIDragItem?
	func canDrop(at indexPath: IndexPath) -> Bool
	func removeItem(from indexPath: IndexPath)
	func insertItems(_ items: [UIDragItem], at indexPath: IndexPath)
}


open class ASCollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    weak var coordinator: ASCollectionViewCoordinator?
    
    open func collectionView(cellShouldSelfSizeHorizontallyForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    open func collectionView(cellShouldSelfSizeVerticallyForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
	
	open var collectionViewContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
		.scrollableAxes
	}
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        coordinator?.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        coordinator?.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath)
    {
        coordinator?.collectionView(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath)
    {
        coordinator?.collectionView(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath)
    }
    
    /*
     //REPLACED WITH CUSTOM PREFETCH SOLUTION AS PREFETCH API WAS NOT WORKING FOR COMPOSITIONAL LAYOUT
     public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])
     public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath])
     */
}

extension ASCollectionViewDelegate: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
	public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard let dragItem = self.coordinator?.dragItem(for: indexPath) else { return [] }
		return [dragItem]
	}
	
	public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		guard session.localDragSession != nil else {
			return UICollectionViewDropProposal(operation: .forbidden)
		}
		if collectionView.hasActiveDrag
		{
			if let destination = destinationIndexPath {
				guard (self.coordinator?.canDrop(at: destination) ?? false) else { return UICollectionViewDropProposal(operation: .cancel) }
			}
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
		else
		{
			return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
		}
	}
	
	public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		var proposedDestinationIndexPath: IndexPath? = coordinator.destinationIndexPath
		
		if proposedDestinationIndexPath == nil && collectionView.numberOfSections != 0
		{
			// Get last index path of collection view.
			let section = collectionView.numberOfSections - 1
			let row = collectionView.numberOfItems(inSection: section)
			proposedDestinationIndexPath = IndexPath(row: row, section: section)
		}
		
		guard let destinationIndexPath = proposedDestinationIndexPath else { return }
		
		switch coordinator.proposal.operation
		{
		case .move:
			coordinator.items.forEach { item in
				if let sourceIndex = item.sourceIndexPath {
					self.coordinator?.removeItem(from: sourceIndex)
				}
			}
			self.coordinator?.insertItems(coordinator.items.map { $0.dragItem }, at: destinationIndexPath)
			/*coordinator.items.forEach { (item) in
				coordinator.drop(item.dragItem, toItemAt: destinationIndexPath) // This assumption is flawed if dropping multiple items
			}*/
			
		case .copy:
			//Add the code to copy items
			break
			
		default:
			return
		}
	}
}

extension ASCollectionView.Coordinator {
    func setupPrefetching()
    {
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
                    let sectionIndexPaths = self.parent.sections[item.section].getIndexPaths(withSectionIndex: item.section)
                    let nextItemsInSection: ArraySlice<IndexPath> = {
                        guard (item.last + 1) < sectionIndexPaths.endIndex else { return [] }
                        return sectionIndexPaths[(item.last + 1) ..< min(item.last + 6, sectionIndexPaths.endIndex)]
                    }()
                    let previousItemsInSection: ArraySlice<IndexPath> = {
                        guard (item.first - 1) >= sectionIndexPaths.startIndex else { return [] }
                        return sectionIndexPaths[max(sectionIndexPaths.startIndex, item.first - 5) ..< item.first]
                    }()
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
                    let lastSection = toPrefetch.keys.max(), // FIND THE LAST VISIBLE SECTION
                    (lastSection + 1) < self.parent.sections.endIndex, // CHECK THERE IS A SECTION AFTER THIS
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

public class AS_CollectionViewController: UIViewController {
	weak var coordinator: ASCollectionViewCoordinator?
	
	var collectionViewLayout: UICollectionViewLayout
	lazy var collectionView: UICollectionView = {
		AS_CollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
	}()
	
	public init(collectionViewLayout layout: UICollectionViewLayout) {
		self.collectionViewLayout = layout
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func viewDidLoad() {
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
	
	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.view.frame = CGRect(origin: self.view.frame.origin, size: size)
		coordinator.animate(alongsideTransition: { (context) in
			self.view.setNeedsLayout()
			self.view.layoutIfNeeded()
			self.collectionViewLayout.invalidateLayout()
		}, completion: nil)
	}
	
	public override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		self.collectionViewLayout.invalidateLayout()
	}
}

class AS_CollectionView: UICollectionView {
	
}
