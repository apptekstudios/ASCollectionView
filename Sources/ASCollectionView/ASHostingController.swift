// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
internal struct ASHostingControllerModifier: ViewModifier
{
	var invalidateCellLayoutCallback: ((_ animated: Bool) -> Void)?
	var collectionViewScrollToCellCallback: ((UICollectionView.ScrollPosition) -> Void)?
	var tableViewScrollToCellCallback: ((UITableView.ScrollPosition) -> Void)?
	func body(content: Content) -> some View
	{
		content
			.environment(\.invalidateCellLayout, invalidateCellLayoutCallback)
			.environment(\.collectionViewScrollToCell, collectionViewScrollToCellCallback)
			.environment(\.tableViewScrollToCell, tableViewScrollToCellCallback)
	}
}

@available(iOS 13.0, *)
internal protocol ASHostingControllerProtocol: AnyObject
{
	var viewController: UIViewController { get }
	var modifier: ASHostingControllerModifier { get set }
	func sizeThatFits(in size: CGSize, maxSize: ASOptionalSize, selfSizeHorizontal: Bool, selfSizeVertical: Bool) -> CGSize
}

@available(iOS 13.0, *)
internal class ASHostingController<ViewType: View>: ASHostingControllerProtocol
{
	init(_ view: ViewType, modifier: ASHostingControllerModifier = ASHostingControllerModifier())
	{
		uiHostingController = .init(rootView: view.modifier(modifier))
	}

	private let uiHostingController: AS_UIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>
	var viewController: UIViewController
	{
		uiHostingController.view.backgroundColor = .clear
		uiHostingController.view.insetsLayoutMarginsFromSafeArea = false
		return uiHostingController as UIViewController
	}

	var disableSwiftUIDropInteraction: Bool
	{
		get { uiHostingController.shouldDisableDrop }
		set { uiHostingController.shouldDisableDrop = newValue }
	}

	var disableSwiftUIDragInteraction: Bool
	{
		get { uiHostingController.shouldDisableDrag }
		set { uiHostingController.shouldDisableDrag = newValue }
	}

	var hostedView: ViewType
	{
		get
		{
			uiHostingController.rootView.content
		}
		set
		{
			uiHostingController.rootView.content = newValue
		}
	}

	var modifier: ASHostingControllerModifier
	{
		get
		{
			uiHostingController.rootView.modifier
		}
		set
		{
			uiHostingController.rootView.modifier = newValue
		}
	}

	func setView(_ view: ViewType)
	{
		hostedView = view
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

@available(iOS 13.0, *)
private class AS_UIHostingController<Content: View>: UIHostingController<Content>
{
	var shouldDisableDrop: Bool = false
	{
		didSet
		{
			disableInteractionsIfNeeded()
		}
	}

	var shouldDisableDrag: Bool = false
	{
		didSet
		{
			disableInteractionsIfNeeded()
		}
	}

	private func disableInteractionsIfNeeded()
	{
		guard let view = viewIfLoaded else { return }
		if shouldDisableDrop
		{
			if let dropInteraction = view.interactions.first(where: {
				$0.isKind(of: UIDropInteraction.self)
			}) as? UIDropInteraction
			{
				view.removeInteraction(dropInteraction)
			}
		}
		if shouldDisableDrag
		{
			if let contextInteraction = view.interactions.first(where: {
				$0.isKind(of: UIDragInteraction.self)
			}) as? UIDragInteraction
			{
				view.removeInteraction(contextInteraction)
			}
		}
	}

	override func loadView()
	{
		super.loadView()
		disableInteractionsIfNeeded()
	}
}
