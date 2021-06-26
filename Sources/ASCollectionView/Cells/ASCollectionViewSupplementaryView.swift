// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASCollectionViewSupplementaryView: UICollectionReusableView, ASDataSourceConfigurableSupplementary
{
	var supplementaryID: ASSupplementaryCellID?
	let hostingController = ASHostingController<AnyView>(AnyView(EmptyView()))

	var isEmpty: Bool = true
	var selfSizingConfig: ASSelfSizingConfig = .init()

	override init(frame: CGRect)
	{
		super.init(frame: frame)
		addSubview(hostingController.viewController.view)
		hostingController.viewController.view.frame = bounds
	}

	@available(*, unavailable)
	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	weak var collectionViewController: AS_CollectionViewController?
	{
		didSet
		{
			if collectionViewController != oldValue
			{
				collectionViewController?.addChild(hostingController.viewController)
				hostingController.viewController.didMove(toParent: collectionViewController)
			}
		}
	}

	override func prepareForReuse()
	{
		super.prepareForReuse()
		supplementaryID = nil
	}

	func setContent<Content: View>(supplementaryID: ASSupplementaryCellID, content: Content?)
	{
		guard let content = content else { setAsEmpty(supplementaryID: supplementaryID); return }
		self.supplementaryID = supplementaryID
		isEmpty = false
		hostingController.setView(AnyView(content.id(supplementaryID)))
	}

	func setAsEmpty(supplementaryID: ASSupplementaryCellID?)
	{
		self.supplementaryID = supplementaryID
		isEmpty = true
		hostingController.setView(AnyView(EmptyView().id(supplementaryID)))
	}

	override public var safeAreaInsets: UIEdgeInsets
	{
		.zero
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		hostingController.viewController.view.frame = bounds
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		guard !isEmpty else { return CGSize(width: 1, height: 1) }
		let selfSizeHorizontal = selfSizingConfig.selfSizeHorizontally ?? (horizontalFittingPriority != .required)
		let selfSizeVertical = selfSizingConfig.selfSizeVertically ?? (verticalFittingPriority != .required)

		guard selfSizeVertical || selfSizeHorizontal
		else
		{
			return targetSize
		}

		// We need to calculate a size for self-sizing. Layout the view to get swiftUI to update its state
		hostingController.viewController.view.setNeedsLayout()
		hostingController.viewController.view.layoutIfNeeded()
		let size = hostingController.sizeThatFits(
			in: targetSize,
			maxSize: maxSizeForSelfSizing,
			selfSizeHorizontal: selfSizeHorizontal,
			selfSizeVertical: selfSizeVertical)
		return size
	}

	var maxSizeForSelfSizing: ASOptionalSize
	{
		ASOptionalSize(
			width: selfSizingConfig.canExceedCollectionWidth ? nil : collectionViewController.map { $0.collectionView.contentSize.width - 0.001 },
			height: selfSizingConfig.canExceedCollectionHeight ? nil : collectionViewController.map { $0.collectionView.contentSize.height - 0.001 })
	}
}
