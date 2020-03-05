// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
internal struct ASHostingControllerModifier: ViewModifier
{
	var invalidateCellLayout: (() -> Void) = {}
	func body(content: Content) -> some View
	{
		content
			.environment(\.invalidateCellLayout, invalidateCellLayout)
	}
}

@available(iOS 13.0, *)
internal protocol ASHostingControllerProtocol: AnyObject
{
	var viewController: UIViewController { get }
	func applyModifier(_ modifier: ASHostingControllerModifier)
	func sizeThatFits(in size: CGSize, maxSize: ASOptionalSize, selfSizeHorizontal: Bool, selfSizeVertical: Bool) -> CGSize
}

@available(iOS 13.0, *)
internal class ASHostingController<ViewType: View>: ASHostingControllerProtocol
{
	init(_ view: ViewType, modifier: ASHostingControllerModifier = ASHostingControllerModifier())
	{
		hostedView = view
		self.modifier = modifier
		uiHostingController = .init(rootView: view.modifier(modifier))
	}

	let uiHostingController: UIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>
	var viewController: UIViewController
	{
		uiHostingController.view.backgroundColor = .clear
		uiHostingController.view.insetsLayoutMarginsFromSafeArea = false
		return uiHostingController as UIViewController
	}

	var hostedView: ViewType
	var modifier: ASHostingControllerModifier
	{
		didSet
		{
			uiHostingController.rootView = hostedView.modifier(modifier)
		}
	}

	func setView(_ view: ViewType)
	{
		hostedView = view
		uiHostingController.rootView = hostedView.modifier(modifier)
	}

	func applyModifier(_ modifier: ASHostingControllerModifier)
	{
		self.modifier = modifier
	}

	func sizeThatFits(in size: CGSize, maxSize: ASOptionalSize, selfSizeHorizontal: Bool, selfSizeVertical: Bool) -> CGSize
	{
		let fittingSize = CGSize(
			width: selfSizeHorizontal ? .infinity : size.width,
			height: selfSizeVertical ? .infinity : size.height).applyMaxSize(maxSize)

		// Find the desired size
		var desiredSize = uiHostingController.sizeThatFits(in: fittingSize)

		// Accounting for 'greedy' swiftUI views that take up as much space as they can
		switch (desiredSize.width, desiredSize.height)
		{
		case (.infinity, .infinity):
			desiredSize = uiHostingController.sizeThatFits(in: size)
		case (.infinity, _):
			desiredSize = uiHostingController.sizeThatFits(in: CGSize(width: size.width, height: fittingSize.height))
		case (_, .infinity):
			desiredSize = uiHostingController.sizeThatFits(in: CGSize(width: fittingSize.width, height: size.height))
		default: break
		}

		// Ensure correct dimensions in non-self sizing axes
		if !selfSizeHorizontal { desiredSize.width = size.width }
		if !selfSizeVertical { desiredSize.height = size.height }

		return desiredSize.applyMaxSize(maxSize)
	}
}
