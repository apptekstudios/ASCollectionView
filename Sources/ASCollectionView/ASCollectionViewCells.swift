// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

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

	var invalidateLayout: (() -> Void)?
	var shouldInvalidateLayout: Bool = false

	private(set) var id: ASCollectionViewItemUniqueID?

	func setupFor(id: ASCollectionViewItemUniqueID, hostingController: ASHostingControllerProtocol?)
	{
		self.hostingController = hostingController
		self.id = id
	}

	func willAppear(in vc: UIViewController?)
	{
		hostingController.map
		{
			$0.viewController.removeFromParent()
			vc?.addChild($0.viewController)
			contentView.addSubview($0.viewController.view)

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
		isSelected = false
		hostingController = nil
		contentView.subviews.forEach { $0.removeFromSuperview() }
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

class ASCollectionViewSupplementaryView: UICollectionReusableView
{
	var hostingController: ASHostingControllerProtocol?

	private(set) var id: Int?

	func setupFor<Content: View>(id: Int, view: Content)
	{
		self.id = id
		hostingController = ASHostingController<Content>(view)
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
			$0.viewController.removeFromParent()
			vc?.addChild($0.viewController)
			addSubview($0.viewController.view)

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
		subviews.forEach { $0.removeFromSuperview() }
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
