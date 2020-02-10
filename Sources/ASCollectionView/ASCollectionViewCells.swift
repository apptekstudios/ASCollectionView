// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class ASCollectionViewCell: UICollectionViewCell
{
	var hostingController: ASHostingControllerProtocol?
	{
		didSet
		{
			let modifier = ASHostingControllerModifier(invalidateCellLayout: {
				self.shouldInvalidateLayout = true
				self.setNeedsLayout()
			})
			hostingController?.applyModifier(modifier)
		}
	}
	
	var maxSizeForSelfSizing: ASOptionalSize = .none

	var invalidateLayout: (() -> Void)?
	var shouldInvalidateLayout: Bool = false

	private(set) var id: ASCollectionViewItemUniqueID?

	func setupFor(id: ASCollectionViewItemUniqueID, hostingController: ASHostingControllerProtocol?)
	{
		self.hostingController = hostingController
		self.id = id
	}

	func willAppear(in vc: UIViewController)
	{
		hostingController.map
			{
				if $0.viewController.parent != vc {
					$0.viewController.removeFromParent()
					vc.addChild($0.viewController)
				}
				if $0.viewController.view.superview != contentView {
					$0.viewController.view.removeFromSuperview()
					contentView.subviews.forEach { $0.removeFromSuperview() }
					contentView.addSubview($0.viewController.view)
				}
				
				setNeedsLayout()
				
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
		hostingController?.viewController.view.frame = contentView.bounds
		hostingController?.viewController.view.setNeedsLayout()
		if shouldInvalidateLayout
		{
			shouldInvalidateLayout = false
			invalidateLayout?()
		}
	}

	var selfSizeHorizontal: Bool = true
	var selfSizeVertical: Bool = true

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else
		{
			return CGSize(width: 1, height: 1)
		} // Can't return .zero as UICollectionViewLayout will crash
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: maxSizeForSelfSizing,
			selfSizeHorizontal: selfSizeHorizontal,
			selfSizeVertical: selfSizeVertical)
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
	
	func setupAsEmptyView() {
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
			if $0.viewController.parent != vc {
				$0.viewController.removeFromParent()
				vc?.addChild($0.viewController)
			}
			if $0.viewController.view.superview != self {
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

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else { return CGSize(width: 1, height: 1) }
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: maxSizeForSelfSizing,
			selfSizeHorizontal: true,
			selfSizeVertical: true)
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
