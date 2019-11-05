// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

public protocol Decoration: View
{
	init()
}

class ASCollectionViewDecoration<Content: Decoration>: ASCollectionViewSupplementaryView
{
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		let view = Content()
		setupFor(id: 0, view: view)
		willAppear(in: nil)
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse()
	{
		// Don't call super, we don't want any changes
	}
}
