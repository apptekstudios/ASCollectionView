// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class ASTableViewSupplementaryView: UITableViewHeaderFooterView, ASDataSourceConfigurableSupplementary
{
	var supplementaryID: ASSupplementaryCellID?
	let hostingController = ASHostingController<AnyView>(AnyView(EmptyView()))
	var isEmpty: Bool = true

	override init(reuseIdentifier: String?)
	{
		super.init(reuseIdentifier: reuseIdentifier)
		backgroundView = UIView()
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
		supplementaryID = nil
	}

	func setContent<Content: View>(supplementaryID: ASSupplementaryCellID, content: Content?)
	{
		guard let content = content else { setAsEmpty(supplementaryID: supplementaryID); return }
		self.supplementaryID = supplementaryID
		isEmpty = false
		hostingController.setView(AnyView(content.id(supplementaryID)))
	}

	func setAsEmpty(supplementaryID: ASSupplementaryCellID?)
	{
		self.supplementaryID = supplementaryID
		isEmpty = true
		hostingController.setView(AnyView(EmptyView().id(supplementaryID)))
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
		guard !isEmpty else { return CGSize(width: 1, height: 1) }
		hostingController.viewController.view.setNeedsLayout()
		hostingController.viewController.view.layoutIfNeeded()
		let size = hostingController.sizeThatFits(
			in: targetSize,
			maxSize: ASOptionalSize(),
			selfSizeHorizontal: false,
			selfSizeVertical: true)
		return size
	}
}
