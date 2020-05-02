// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASCollectionViewCell: UICollectionViewCell, ASDataSourceConfigurableCell
{
	var indexPath: IndexPath?
	var itemID: ASCollectionViewItemUniqueID?
	var hostingController: ASHostingControllerProtocol?
	{
		didSet
		{
			hostingController?.invalidateCellLayoutCallback = invalidateLayoutCallback
			hostingController?.collectionViewScrollToCellCallback = scrollToCellCallback
		}
	}

	weak var collectionView: UICollectionView?

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)

	var invalidateLayoutCallback: ((_ animated: Bool) -> Void)?
	var scrollToCellCallback: ((UICollectionView.ScrollPosition) -> Void)?

	func willAppear(in vc: UIViewController)
	{
		if hostingController?.viewController.parent != vc
		{
			hostingController?.viewController.removeFromParent()
			hostingController.map { vc.addChild($0.viewController) }
			hostingController?.viewController.didMove(toParent: vc)
		}
	}

	func didDisappear()
	{
		hostingController?.viewController.removeFromParent()
	}

	private func attachView()
	{
		guard let hcView = hostingController?.viewController.view else
		{
			detachViews()
			return
		}
		guard !isHidden else { return }
		if hcView.superview != contentView
		{
			contentView.subviews.forEach { $0.removeFromSuperview() }
			contentView.addSubview(hcView)
			setNeedsLayout()
		}
	}

	private func detachViews()
	{
		contentView.subviews.forEach { $0.removeFromSuperview() }
	}

	var shouldSkipNextRefresh: Bool = true

	override func prepareForReuse()
	{
		indexPath = nil
		itemID = nil
		isSelected = false
		hostingController = nil
		shouldSkipNextRefresh = true
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		attachView()

		if hostingController?.viewController.view.frame != contentView.bounds
		{
			UIView.performWithoutAnimation {
				hostingController?.viewController.view.frame = contentView.bounds
				hostingController?.viewController.view.setNeedsLayout()
				hostingController?.viewController.view.layoutIfNeeded()
			}
		}
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else
		{
			return CGSize(width: 1, height: 1)
		} // Can't return .zero as UICollectionViewLayout will crash

		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: maxSizeForSelfSizing,
			selfSizeHorizontal: selfSizingConfig.selfSizeHorizontally,
			selfSizeVertical: selfSizingConfig.selfSizeVertically)
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}

	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes
	{
		layoutAttributes.size = systemLayoutSizeFitting(layoutAttributes.size)
		return layoutAttributes
	}

	var maxSizeForSelfSizing: ASOptionalSize
	{
		ASOptionalSize(
			width: selfSizingConfig.canExceedCollectionWidth ? nil : collectionView.map { $0.contentSize.width - 0.001 },
			height: selfSizingConfig.canExceedCollectionHeight ? nil : collectionView.map { $0.contentSize.height - 0.001 })
	}
}
