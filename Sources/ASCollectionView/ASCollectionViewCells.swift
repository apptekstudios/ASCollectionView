// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

class ASCollectionViewCell: UICollectionViewCell
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

	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes
	{
		guard let hc = hostingController else { return layoutAttributes }
        let sizeThatFits = hc.viewController.view.sizeThatFits(layoutAttributes.size)
		layoutAttributes.size = sizeThatFits
		return layoutAttributes
	}
}

class ASCollectionViewSupplementaryView: UICollectionReusableView
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
			hostingController = nil
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
			hostingController = nil
			return
		}
		hostingController?.rootView = view
	}

	func willAppear(in vc: UIViewController?)
	{
		if hostingController?.parent !== vc
		{
			hostingController?.removeFromParent()
			hostingController.map
			{
				vc?.addChild($0)
				if $0.view.superview !== self
				{
					subviews.forEach { $0.removeFromSuperview() }
					addSubview($0.view)
				}
			}
			setNeedsLayout()
			vc.map { hostingController?.didMove(toParent: $0) }
		}
	}

	func didDisappear()
	{
		subviews.forEach { $0.removeFromSuperview() }
		hostingController?.removeFromParent()
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()
		hostingController?.view.frame = bounds
	}

	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes
	{
		layoutAttributes.size = hostingController?.sizeThatFits(in: layoutAttributes.size) ?? CGSize(width: 1, height: 1)
		return layoutAttributes
	}
}
