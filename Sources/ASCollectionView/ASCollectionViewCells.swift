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
	var hostingController: ASHostingControllerProtocol?
	{
		didSet
		{
			if let hc = hostingController
			{
				if hc.viewController.view.superview != contentView
				{
					contentView.subviews.forEach { $0.removeFromSuperview() }
				}
			}
			else
			{
				contentView.subviews.forEach { $0.removeFromSuperview() }
			}
		}
	}

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)
	var maxSizeForSelfSizing: ASOptionalSize = .none

	var invalidateLayout: (() -> Void)?

	private(set) var itemID: ASCollectionViewItemUniqueID?

	func configureAsEmpty()
	{
		hostingController = nil
	}

	func configureHostingController<Content: View>(forItemID itemID: ASCollectionViewItemUniqueID, content: Content, usingCachedController cachedHC: ASHostingControllerProtocol?)
	{
		self.itemID = itemID

		if let existingHC = cachedHC as? ASHostingController<Content>
		{
			existingHC.setView(content)
			hostingController = existingHC
		}
		else
		{
			let modifier = ASHostingControllerModifier(invalidateCellLayout: { [weak self] in
				self?.invalidateLayout?()
			})
			let newHC = ASHostingController<Content>(content, modifier: modifier)
			hostingController = newHC
		}
	}

	func willAppear(in vc: UIViewController)
	{
		hostingController.map
		{ hc in
			if hc.viewController.parent != vc
			{
				hc.viewController.removeFromParent()
				vc.addChild(hc.viewController)
			}

			if hc.viewController.view.superview != contentView
			{
				contentView.subviews.forEach { $0.removeFromSuperview() }
				contentView.addSubview(hc.viewController.view)
				setNeedsLayout()
			}

			hostingController?.viewController.didMove(toParent: vc)
		}
	}

	func didDisappear()
	{
		hostingController?.viewController.removeFromParent()
	}

	override func prepareForReuse()
	{
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
}

@available(iOS 13.0, *)
class ASCollectionViewSupplementaryView: UICollectionReusableView
{
	var hostingController: ASHostingControllerProtocol?
	private(set) var id: Int?

	var maxSizeForSelfSizing: ASOptionalSize = .none

	func setupFor<Content: View>(id: Int, view: Content)
	{
		self.id = id
		hostingController = ASHostingController<Content>(view)
	}

	func setupAsEmptyView()
	{
		hostingController = nil
		subviews.forEach { $0.removeFromSuperview() }
	}

	func updateView<Content: View>(_ view: Content)
	{
		guard let hc = hostingController as? ASHostingController<Content> else { return }
		hc.setView(view)
	}

	func willAppear(in vc: UIViewController?)
	{
		hostingController.map
		{
			if $0.viewController.parent != vc
			{
				$0.viewController.removeFromParent()
				vc?.addChild($0.viewController)
			}
			if $0.viewController.view.superview != self
			{
				$0.viewController.view.removeFromSuperview()
				subviews.forEach { $0.removeFromSuperview() }
				addSubview($0.viewController.view)
			}

			setNeedsLayout()

			vc.map { hostingController?.viewController.didMove(toParent: $0) }
		}
	}

	func didDisappear()
	{
		hostingController?.viewController.removeFromParent()
	}

	override func prepareForReuse()
	{
		hostingController = nil
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()
		hostingController?.viewController.view.frame = bounds
		hostingController?.viewController.view.setNeedsLayout()
	}

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)

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
