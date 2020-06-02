// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASCollectionViewSupplementaryView: UICollectionReusableView, ASDataSourceConfigurableCell
{
	var supplementaryID: ASSupplementaryCellID?
	var hostingController: ASHostingControllerProtocol?
	{
		get { _hostingController }
		set { _hostingController = newValue; attachView() }
	}

	private var _hostingController: ASHostingControllerProtocol?

	var selfSizingConfig: ASSelfSizingConfig = .init()

	weak var collectionViewController: AS_CollectionViewController?

	private var hasAppeared: Bool = false // Needed due to the `self-sizing` cell used by UICV
	func willAppear()
	{
		hasAppeared = true
		attachView()
	}

	func didDisappear()
	{
		hasAppeared = false
		detachViews()
	}

	private func attachView()
	{
		guard hasAppeared else { return }
		guard let hcView = hostingController?.viewController.view else
		{
			detachViews()
			return
		}
		if hcView.superview != self
		{
			hostingController.map { collectionViewController?.addChild($0.viewController) }
			subviews.forEach { $0.removeFromSuperview() }
			addSubview(hcView)
			hcView.frame = bounds
			hostingController?.viewController.didMove(toParent: collectionViewController)
		}
	}

	private func detachViews()
	{
		hostingController?.viewController.willMove(toParent: nil)
		subviews.forEach { $0.removeFromSuperview() }
		hostingController?.viewController.removeFromParent()
	}

	override func prepareForReuse()
	{
		supplementaryID = nil
		_hostingController = nil
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		if hostingController?.viewController.view.frame != bounds
		{
			hostingController?.viewController.view.frame = bounds
			hostingController?.viewController.view.setNeedsLayout()
		}
		hostingController?.viewController.view.layoutIfNeeded()
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		guard let hostingController = hostingController else { return CGSize(width: 1, height: 1) }

		let selfSizeHorizontal = selfSizingConfig.selfSizeHorizontally ?? (horizontalFittingPriority != .required)
		let selfSizeVertical = selfSizingConfig.selfSizeVertically ?? (verticalFittingPriority != .required)

		guard selfSizeVertical || selfSizeHorizontal else
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
