// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

internal struct ASHostingControllerModifier: ViewModifier
{
	var invalidateCellLayout: (() -> Void) = {}
	func body(content: Content) -> some View
	{
		content
			.environment(\.invalidateCellLayout, invalidateCellLayout)
	}
}

internal protocol ASHostingControllerProtocol
{
    var viewController: UIViewController { get }
	func applyModifier(_ modifier: ASHostingControllerModifier)
	func sizeThatFits(in size: CGSize) -> CGSize
}

internal class ASHostingController<ViewType: View>: ASHostingControllerProtocol {
    init(_ view: ViewType)
    {
        hostedView = view
        uiHostingController = .init(rootView: view.modifier(ASHostingControllerModifier()))
    }
    
    let uiHostingController: UIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>
    var viewController: UIViewController {
        uiHostingController as UIViewController
    }
    
    var hostedView: ViewType
    var modifier: ASHostingControllerModifier = ASHostingControllerModifier()
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
    
    func sizeThatFits(in size: CGSize, horizontalPriority: UILayoutPriority, verticalPriority: UILayoutPriority) -> CGSize {
        uiHostingController.view.systemLayoutSizeFitting(size, withHorizontalFittingPriority: horizontalPriority, verticalFittingPriority: verticalPriority)
    }
}
