// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASCollectionViewSupplementaryView: UICollectionReusableView
{
	var hostingController: ASHostingControllerProtocol?

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)
	var maxSizeForSelfSizing: ASOptionalSize = .none

	func willAppear(in vc: UIViewController?)
	{
		if hostingController?.viewController.parent != vc
		{
			hostingController?.viewController.removeFromParent()
			hostingController.map { vc?.addChild($0.viewController) }
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
		if hcView.superview != self
		{
			subviews.forEach { $0.removeFromSuperview() }
			addSubview(hcView)
			setNeedsLayout()
		}
	}

	private func detachViews()
	{
		subviews.forEach { $0.removeFromSuperview() }
	}

	var shouldSkipNextRefresh: Bool = true
	override func prepareForReuse()
	{
		hostingController = nil
		shouldSkipNextRefresh = true
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		attachView()

		if hostingController?.viewController.view.frame != bounds
		{
			UIView.performWithoutAnimation {
				hostingController?.viewController.view.frame = bounds
				hostingController?.viewController.view.setNeedsLayout()
				hostingController?.viewController.view.layoutIfNeeded()
			}
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
