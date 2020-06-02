// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import UIKit

extension UIView
{
	func findFirstResponder() -> UIView?
	{
		if isFirstResponder
		{
			return self
		}
		else
		{
			for subview in subviews
			{
				if let found = subview.findFirstResponder()
				{
					return found
				}
			}
		}
		return nil
	}
}
