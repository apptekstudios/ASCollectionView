// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASTableViewCell: UITableViewCell, ASDataSourceConfigurableCell
{
	var itemID: ASCollectionViewItemUniqueID?
	let hostingController = ASHostingController<AnyView>(AnyView(EmptyView()))
//	var skipNextRefresh: Bool = false

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: .default, reuseIdentifier: reuseIdentifier)
		backgroundColor = nil
		selectionStyle = .default

		let selectedBack = UIView()
		selectedBack.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
		selectedBackgroundView = selectedBack

		contentView.addSubview(hostingController.viewController.view)
		hostingController.viewController.view.frame = contentView.bounds
	}

	@available(*, unavailable)
	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	weak var tableViewController: AS_TableViewController?
	{
		didSet
		{
			if tableViewController != oldValue
			{
				hostingController.viewController.didMove(toParent: tableViewController)
				tableViewController?.addChild(hostingController.viewController)
			}
		}
	}

	override func prepareForReuse()
	{
		super.prepareForReuse()

		itemID = nil
		isSelected = false
		backgroundColor = nil
		alpha = 1.0
//		skipNextRefresh = false
	}

	func setContent<Content: View>(itemID: ASCollectionViewItemUniqueID, content: Content)
	{
		self.itemID = itemID
		hostingController.setView(AnyView(content.id(itemID)))
	}

	override public var safeAreaInsets: UIEdgeInsets
	{
		.zero
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		hostingController.viewController.view.frame = contentView.bounds
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		hostingController.viewController.view.setNeedsLayout()
		hostingController.viewController.view.layoutIfNeeded()
		let size = hostingController.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: true)
		return size
	}

	var disableSwiftUIDropInteraction: Bool
	{
		get { hostingController.disableSwiftUIDropInteraction }
		set { hostingController.disableSwiftUIDropInteraction = newValue }
	}

	var disableSwiftUIDragInteraction: Bool
	{
		get { hostingController.disableSwiftUIDragInteraction }
		set { hostingController.disableSwiftUIDragInteraction = newValue }
	}
}
