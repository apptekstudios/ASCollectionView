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
	func applyModifier(_ modifier: ASHostingControllerModifier)
	func sizeThatFits(in size: CGSize) -> CGSize
}

internal class ASHostingController<ViewType: View>: UIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>, ASHostingControllerProtocol
{
	init(_ view: ViewType)
	{
		hostedView = view
		super.init(rootView: view.modifier(modifier))
	}
	
	var hostedView: ViewType
	var modifier: ASHostingControllerModifier = ASHostingControllerModifier()
	{
		didSet
		{
			rootView = hostedView.modifier(modifier)
		}
	}
	
	func setView(_ view: ViewType)
	{
		hostedView = view
		rootView = hostedView.modifier(modifier)
	}
	
	func applyModifier(_ modifier: ASHostingControllerModifier)
	{
		self.modifier = modifier
	}
	
	@objc dynamic required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}
