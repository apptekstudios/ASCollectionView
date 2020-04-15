// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
protocol ASDataSourceConfigurableCell
{
	var hostingController: ASHostingControllerProtocol? { get set }
}

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
		hostingController.map
		{ hc in
			if hc.viewController.parent != vc
			{
				hc.viewController.removeFromParent()
				vc.addChild(hc.viewController)
			}

			attachView()

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
			contentView.subviews.forEach { $0.removeFromSuperview() }
			return
		}
		if hcView.superview != contentView
		{
			contentView.subviews.forEach { $0.removeFromSuperview() }
			contentView.addSubview(hcView)
			setNeedsLayout()
		}
	}

	override func prepareForReuse()
	{
		indexPath = nil
		itemID = nil
		isSelected = false
		hostingController = nil
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		if hostingController?.viewController.view.frame != contentView.bounds
		{
			hostingController?.viewController.view.frame = contentView.bounds
			hostingController?.viewController.view.setNeedsLayout()
			hostingController?.viewController.view.layoutIfNeeded()
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

@available(iOS 13.0, *)
class ASCollectionViewSupplementaryView: UICollectionReusableView
{
	var hostingController: ASHostingControllerProtocol?
	private(set) var id: Int?

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)
	var maxSizeForSelfSizing: ASOptionalSize = .none

	func setupFor<Content: View>(id: Int, view: Content)
	{
		self.id = id
		if let hc = hostingController as? ASHostingController<Content>
		{
			hc.setView(view)
		}
		else
		{
			hostingController = ASHostingController<Content>(view)
		}
	}

	func setupForEmpty(id: Int)
	{
		self.id = id
		hostingController = nil
		subviews.forEach { $0.removeFromSuperview() }
	}

	func willAppear(in vc: UIViewController?)
	{
		hostingController.map
		{ hc in
			if hc.viewController.parent != vc
			{
				hc.viewController.removeFromParent()
				vc?.addChild(hc.viewController)
			}

			attachView()

			vc.map { hostingController?.viewController.didMove(toParent: $0) }
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
			subviews.forEach { $0.removeFromSuperview() }
			return
		}
		if hcView.superview != self
		{
			subviews.forEach { $0.removeFromSuperview() }
			addSubview(hcView)
		}
	}

	override func prepareForReuse()
	{
		hostingController = nil
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		if hostingController?.viewController.view.frame != bounds
		{
			hostingController?.viewController.view.frame = bounds
			hostingController?.viewController.view.setNeedsLayout()
			hostingController?.viewController.view.layoutIfNeeded()
		}
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else { return CGSize(width: 1, height: 1) }
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
}
