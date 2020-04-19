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
		}
	}

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: false, selfSizeVertically: true)

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
			attachView()
			hostingController?.viewController.didMove(toParent: vc)
		} else {
			attachView()
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
		backgroundColor = nil
		indexPath = nil
		itemID = nil
		hostingController = nil
		isSelected = false
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		let modifiedBounds = CGRect(
			x: contentView.bounds.origin.x,
			y: contentView.bounds.origin.y,
			width: max(fittedSize.width, contentView.bounds.width),
			height: max(fittedSize.height, contentView.bounds.height))
		if hostingController?.viewController.view.frame != modifiedBounds
		{
			hostingController?.viewController.view.frame = modifiedBounds
			hostingController?.viewController.view.setNeedsLayout()
			hostingController?.viewController.view.layoutIfNeeded()
		}
	}

	func prepareForSizing()
	{
		hostingController?.viewController.view.setNeedsLayout()
		hostingController?.viewController.view.layoutIfNeeded()
	}

	var fittedSize: CGSize = .zero
	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else { return .zero }
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: selfSizingConfig.selfSizeVertically)
		fittedSize = size
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}
}
