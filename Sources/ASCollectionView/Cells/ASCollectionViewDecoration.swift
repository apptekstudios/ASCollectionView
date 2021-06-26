// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
public protocol Decoration: View
{
	init()
}

@available(iOS 13.0, *)
class ASCollectionViewDecoration<Content: Decoration>: ASCollectionViewSupplementaryView
{
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setContent(supplementaryID: ASSupplementaryCellID(sectionIDHash: 0, supplementaryKind: "Decoration"), content: Content())
	}
}
