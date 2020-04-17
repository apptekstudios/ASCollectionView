// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class AS_CollectionViewController: UIViewController
{
	weak var coordinator: ASCollectionViewCoordinator?
	{
		didSet
		{
			guard viewIfLoaded != nil else { return }
			collectionView.coordinator = coordinator
		}
	}

	var collectionViewLayout: UICollectionViewLayout
	lazy var collectionView: AS_UICollectionView = {
		let cv = AS_UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
		cv.coordinator = coordinator
		return cv
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

	public override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		// NOTE: Due to some SwiftUI bugs currently, we've chosen to make it so that onMoveToParent is currently called from viewWillAppear
		coordinator?.onMoveToParent()
	}

	public override func didMove(toParent parent: UIViewController?)
	{
		super.didMove(toParent: parent)
		// NOTE: Due to some SwiftUI bugs currently, we've chosen to make it so that onMoveToParent is currently called from viewWillAppear
		if parent == nil
		{
			coordinator?.onMoveFromParent()
		}
	}

	public override func loadView()
	{
		view = collectionView
	}

	public override func viewDidLoad()
	{
		super.viewDidLoad()
		view.backgroundColor = .clear
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

@available(iOS 13.0, *)
class AS_UICollectionView: UICollectionView
{
	weak var coordinator: ASCollectionViewCoordinator?
}
