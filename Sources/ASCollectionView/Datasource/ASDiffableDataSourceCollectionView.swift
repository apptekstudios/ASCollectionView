// ASCollectionView. Created by Apptek Studios 2019

import DifferenceKit
import UIKit

@available(iOS 13.0, *)
class ASDiffableDataSourceCollectionView<SectionID: Hashable>: ASDiffableDataSource<SectionID>, UICollectionViewDataSource
{
	/// The type of closure providing the cell.
	public typealias Snapshot = ASDiffableDataSourceSnapshot<SectionID>
	public typealias CellProvider = (UICollectionView, IndexPath, ASCollectionViewItemUniqueID) -> ASCollectionViewCell?
	public typealias SupplementaryProvider = (UICollectionView, String, IndexPath) -> ASCollectionViewSupplementaryView?

	private weak var collectionView: UICollectionView?
	var cellProvider: CellProvider
	var supplementaryViewProvider: SupplementaryProvider?

	public init(collectionView: UICollectionView, cellProvider: @escaping CellProvider)
	{
		self.collectionView = collectionView
		self.cellProvider = cellProvider
		super.init()

		collectionView.dataSource = self
		collectionView.register(ASCollectionViewSupplementaryView.self, forSupplementaryViewOfKind: supplementaryEmptyKind, withReuseIdentifier: supplementaryEmptyReuseID)
	}

	private var firstLoad: Bool = true

	func applySnapshot(_ newSnapshot: Snapshot, animated: Bool = true, completion: (() -> Void)? = nil)
	{
		let changeset = StagedChangeset(source: currentSnapshot.sections, target: newSnapshot.sections)

		guard let collectionView = collectionView else { return }

		CATransaction.begin()
		if firstLoad || !animated
		{
			firstLoad = false
			CATransaction.setDisableActions(true)
		}
		CATransaction.setCompletionBlock(completion)
		collectionView.reload(using: changeset, interrupt: { $0.changeCount > 100 }) { newSections in
			self.currentSnapshot = .init(sections: newSections)
		}
		CATransaction.commit()
	}

	func numberOfSections(in collectionView: UICollectionView) -> Int
	{
		currentSnapshot.sections.count
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		currentSnapshot.sections[section].elements.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let itemIdentifier = identifier(at: indexPath)
		guard let cell = cellProvider(collectionView, indexPath, itemIdentifier) else
		{
			fatalError("ASCollectionView dataSource returned a nil cell for row at index path: \(indexPath), collectionView: \(collectionView), itemIdentifier: \(itemIdentifier)")
		}
		return cell
	}

	private let supplementaryEmptyKind = UUID().uuidString // Used to prevent crash if supplementaries defined in layout but not provided by the section
	private let supplementaryEmptyReuseID = UUID().uuidString

	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
	{
		guard let cell = supplementaryViewProvider?(collectionView, kind, indexPath) else
		{
			let empty = collectionView.dequeueReusableSupplementaryView(ofKind: supplementaryEmptyKind, withReuseIdentifier: supplementaryEmptyReuseID, for: indexPath)
			(empty as? ASCollectionViewSupplementaryView)?.hostingController = nil
			return empty
		}
		return cell
	}
}
