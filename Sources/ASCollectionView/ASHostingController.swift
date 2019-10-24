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
	func sizeThatFits(in size: CGSize, horizontalPriority: UILayoutPriority, verticalPriority: UILayoutPriority) -> CGSize
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
        let prioritisedSize = CGSize(width: horizontalPriority == UILayoutPriority.fittingSizeLevel ? .infinity : size.width,
                                     height: verticalPriority == UILayoutPriority.fittingSizeLevel ? .infinity : size.height )
        var desiredSize = uiHostingController.view.systemLayoutSizeFitting(prioritisedSize, withHorizontalFittingPriority: horizontalPriority, verticalFittingPriority: verticalPriority)
        
        //Accounting for 'greedy' swiftUI views that take up as much space as they can
        switch (desiredSize.width, desiredSize.height) {
        case (.infinity, .infinity):
            desiredSize = uiHostingController.view.systemLayoutSizeFitting(size, withHorizontalFittingPriority: horizontalPriority, verticalFittingPriority: verticalPriority)
        case (.infinity, _):
            desiredSize = uiHostingController.view.systemLayoutSizeFitting(CGSize(width: size.width, height: prioritisedSize.height), withHorizontalFittingPriority: horizontalPriority, verticalFittingPriority: verticalPriority)
        case (_, .infinity):
            desiredSize = uiHostingController.view.systemLayoutSizeFitting(CGSize(width: prioritisedSize.width, height: size.height), withHorizontalFittingPriority: horizontalPriority, verticalFittingPriority: verticalPriority)
        default: break
        }
        return desiredSize
    }
}
