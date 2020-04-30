// ASCollectionView. Created by Apptek Studios 2019

import UIKit

extension UIScrollView
{
	var contentSizePlusInsets: CGSize
	{
		CGSize(
			width: contentSize.width + adjustedContentInset.left + adjustedContentInset.right,
			height: contentSize.height + adjustedContentInset.bottom + contentInset.top) // NOTE: the adjusted top inset intentionally left out, as SwiftUI uses a negative contentOffset to display the nav bar (doesn't affect content size)
	}

	var maxContentOffset: CGPoint
	{
		CGPoint(
			x: max(0, contentSizePlusInsets.width - bounds.width),
			y: max(0, contentSizePlusInsets.height + safeAreaInsets.top - bounds.height))
	}
}
