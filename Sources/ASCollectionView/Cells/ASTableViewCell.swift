// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASTableViewCell: UITableViewCell, ASDataSourceConfigurableCell
{
	var indexPath: IndexPath?
	var itemID: ASCollectionViewItemUniqueID?
	var hostingController: ASHostingControllerProtocol?
	{
		didSet
		{
			hostingController?.invalidateCellLayoutCallback = invalidateLayoutCallback
			hostingController?.tableViewScrollToCellCallback = scrollToCellCallback
			if hostingController !== oldValue, hostingController != nil
			{
				attachView()
			}
		}
	}

	var invalidateLayoutCallback: ((_ animated: Bool) -> Void)?
	var scrollToCellCallback: ((UITableView.ScrollPosition) -> Void)?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: .default, reuseIdentifier: reuseIdentifier)
		backgroundColor = nil
		selectionStyle = .none
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
			hostingController?.viewController.didMove(toParent: vc)
		}
	}

	func didDisappear()
	{
		hostingController?.viewController.removeFromParent()
	}

	override func didMoveToSuperview()
	{
		attachView()
	}

	private func attachView()
	{
		guard superview != nil else { return }
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

	var shouldSkipNextRefresh: Bool = true // This is used to avoid double-up in reloaded cells and our update from swiftUI
	override func prepareForReuse()
	{
		backgroundColor = nil
		indexPath = nil
		itemID = nil
		hostingController = nil
		isSelected = false
		shouldSkipNextRefresh = true
	}

	func recalculateSize()
	{
		hostingController?.viewController.view.setNeedsLayout()
		hostingController?.viewController.view.layoutIfNeeded()
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		if hostingController?.viewController.view.frame != contentView.bounds
		{
			UIView.performWithoutAnimation {
				hostingController?.viewController.view.frame = contentView.bounds
				hostingController?.viewController.view.setNeedsLayout()
				hostingController?.viewController.view.layoutIfNeeded()
			}
		}
	}

	var fittedSize: CGSize = .zero
	{
		didSet
		{
			if fittedSize != oldValue
			{
				setNeedsLayout()
				layoutIfNeeded()
			}
		}
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else { return .zero }
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: true)
		fittedSize = size
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}
}
