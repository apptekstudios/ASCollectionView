// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASTableViewSupplementaryView: UITableViewHeaderFooterView
{
	var hostingController: ASHostingControllerProtocol?

	var sectionIDHash: Int?
	var supplementaryKind: String?

	override init(reuseIdentifier: String?)
	{
		super.init(reuseIdentifier: reuseIdentifier)
		backgroundView = UIView()
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	func willAppear(in vc: UIViewController)
	{
		if hostingController?.viewController.parent != vc
		{
			hostingController?.viewController.removeFromParent()
			hostingController.map { vc.addChild($0.viewController) }
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
			detachViews()
			return
		}
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
		hostingController = nil
		sectionIDHash = nil
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
		guard let hc = hostingController else { return CGSize(width: 1, height: 1) }
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: true)
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}
}
