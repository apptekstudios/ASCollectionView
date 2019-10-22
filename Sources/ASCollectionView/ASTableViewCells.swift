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
            hostingController?.viewController.view.backgroundColor = .clear
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
    
    func update(_ hostingController: ASHostingControllerProtocol?)
    {
        self.hostingController = hostingController
    }
    
    func willAppear(in vc: UIViewController?)
    {
        hostingController?.viewController.removeFromParent()
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        hostingController.map
            {
                vc?.addChild($0.viewController)
                contentView.addSubview($0.viewController.view)
                
                setNeedsLayout()
                
                vc.map { hostingController?.viewController.didMove(toParent: $0) }
        }
    }
    
    func didDisappear()
    {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        hostingController?.viewController.removeFromParent()
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

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		guard let hc = hostingController else
		{
			return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		}
		return hc.sizeThatFits(in: targetSize)
	}
}

class ASTableViewSupplementaryView: UITableViewHeaderFooterView
{
	var hostingController: UIHostingController<AnyView>?
	{
		didSet
		{
			hostingController?.view.backgroundColor = .clear
		}
	}

	private(set) var id: Int?

	func setupFor(id: Int, view: AnyView?)
	{
		guard let view = view else
		{
			hostingController?.view.removeFromSuperview()
			hostingController?.removeFromParent()
			return
		}
		if let hc = hostingController
		{
			hc.rootView = view
		}
		else
		{
			hostingController = UIHostingController(rootView: view)
		}
		self.id = id
	}

	func updateView(_ view: AnyView?)
	{
		guard let view = view else
		{
			hostingController?.view.removeFromSuperview()
			hostingController?.removeFromParent()
			return
		}
		withAnimation
		{
			hostingController?.rootView = view
		}
	}

	func willAppear(in vc: UIViewController?)
	{
		if hostingController?.parent !== vc
		{
			hostingController?.removeFromParent()
			hostingController.map
			{
				vc?.addChild($0)
				if $0.view.superview !== contentView
				{
					contentView.subviews.forEach { $0.removeFromSuperview() }
					contentView.addSubview($0.view)
				}
			}
			setNeedsLayout()
			vc.map { hostingController?.didMove(toParent: $0) }
		}
	}

	func didDisappear()
	{
		contentView.subviews.forEach { $0.removeFromSuperview() }
		hostingController?.removeFromParent()
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize
	{
		guard let hc = hostingController else
		{
			return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		}
		return hc.view.sizeThatFits(targetSize)
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()
		hostingController?.view.frame = bounds
	}
}
