// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

class ASTableViewCell: UITableViewCell
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
		selectionStyle = .none
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
		hostingController = nil
		contentView.subviews.forEach { $0.removeFromSuperview() }
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()
		hostingController?.viewController.view.frame = contentView.bounds
		if shouldInvalidateLayout
		{
			shouldInvalidateLayout = false
			invalidateLayout?()
		}
	}

	var selfSizeVertical: Bool = true

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize
	{
		guard let hc = hostingController else { return .zero }
		let size = hc.sizeThatFits(
			in: targetSize,
			selfSizeHorizontal: false,
			selfSizeVertical: selfSizeVertical)
		return size
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		systemLayoutSizeFitting(targetSize)
	}
}

class ASTableViewSupplementaryView: UITableViewHeaderFooterView
{
	var hostingController: ASHostingControllerProtocol?

	private(set) var id: Int?

	override init(reuseIdentifier: String?)
	{
		super.init(reuseIdentifier: reuseIdentifier)
		backgroundView = UIView()
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	func setupFor<Content: View>(id: Int, view: Content?)
	{
		self.id = id
		if let view = view
		{
			hostingController = ASHostingController<Content>(view)
		}
		else
		{
			hostingController = nil
			contentView.subviews.forEach { $0.removeFromSuperview() }
		}
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
		hostingController = nil
		contentView.subviews.forEach { $0.removeFromSuperview() }
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()
		hostingController?.viewController.view.frame = contentView.bounds
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
}
