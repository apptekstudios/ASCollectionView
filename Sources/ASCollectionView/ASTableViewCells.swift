// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

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
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		backgroundColor = nil
		selectionStyle = .none
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
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
		}
	}

	override func prepareForReuse()
	{
		backgroundColor = .clear
		indexPath = nil
		itemID = nil
		hostingController = nil
		isSelected = false
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

	func prepareForSizing()
	{
		hostingController?.viewController.view.setNeedsLayout()
		hostingController?.viewController.view.layoutIfNeeded()
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else { return .zero }
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: selfSizingConfig.selfSizeVertically)
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}
}

@available(iOS 13.0, *)
class ASTableViewSupplementaryView: UITableViewHeaderFooterView
{
	var hostingController: ASHostingControllerProtocol?
	private(set) var id: Int?

	var selfSizingConfig: ASSelfSizingConfig = .init(selfSizeHorizontally: false, selfSizeVertically: true)

	override init(reuseIdentifier: String?)
	{
		super.init(reuseIdentifier: reuseIdentifier)
		backgroundView = UIView()
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

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
		contentView.subviews.forEach { $0.removeFromSuperview() }
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
		}
	}

	override func prepareForReuse()
	{
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
		guard let hc = hostingController else { return CGSize(width: 1, height: 1) }
		let size = hc.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: selfSizingConfig.selfSizeVertically)
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}
}
