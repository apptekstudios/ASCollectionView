// ASCollectionView. Created by Apptek Studios 2019

import UIKit

extension UITableView
{
	/// The section header views that are visible in the table view.
	var visibleHeaderViews: [UITableViewHeaderFooterView]
	{
		visibleSections.compactMap { index in
			headerView(forSection: index)
		}
	}

	/// The section footer views that are visible in the table view.
	var visibleFooterViews: [UITableViewHeaderFooterView]
	{
		visibleSections.compactMap { index in
			footerView(forSection: index)
		}
	}

	var visibleSections: [Int]
	{
		indexPathsForVisibleRows.map {
			Array($0.reduce(into: Set<Int>()) { result, indexPath in
				result.insert(indexPath.section)
			})
		} ?? []
	}
}
