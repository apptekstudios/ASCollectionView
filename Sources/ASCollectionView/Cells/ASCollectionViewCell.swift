// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASCollectionViewCell: UICollectionViewCell, ASDataSourceConfigurableCell
{
	var itemID: ASCollectionViewItemUniqueID?
	let hostingController = ASHostingController<AnyView>(AnyView(EmptyView()))
//	var skipNextRefresh: Bool = false

	override init(frame: CGRect)
	{
		super.init(frame: frame)
		contentView.addSubview(hostingController.viewController.view)
		hostingController.viewController.view.frame = contentView.bounds
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

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)

	override func prepareForReuse()
	{
		super.prepareForReuse()
		itemID = nil
		isSelected = false
		alpha = 1.0
//		skipNextRefresh = false
	}

	override public var safeAreaInsets: UIEdgeInsets
	{
		.zero
	}

	func setContent<Content: View>(itemID: ASCollectionViewItemUniqueID, content: Content)
	{
		self.itemID = itemID
		hostingController.setView(AnyView(content.id(itemID)))
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		hostingController.viewController.view.frame = contentView.bounds
		hostingController.viewController.view.layoutIfNeeded()
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
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

	var disableSwiftUIDropInteraction: Bool
	{
		get { hostingController.disableSwiftUIDropInteraction }
		set { hostingController.disableSwiftUIDropInteraction = newValue }
	}

	var disableSwiftUIDragInteraction: Bool
	{
		get { hostingController.disableSwiftUIDragInteraction }
		set { hostingController.disableSwiftUIDragInteraction = newValue }
	}
}
