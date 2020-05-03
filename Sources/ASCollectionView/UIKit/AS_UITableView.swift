// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class AS_TableViewController: UIViewController
{
	weak var coordinator: ASTableViewCoordinator?

	var style: UITableView.Style

	lazy var tableView: AS_UITableView = {
		let tableView = AS_UITableView(frame: .zero, style: style)
		tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude))) // Remove unnecessary padding in Style.grouped/insetGrouped
		tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude))) // Remove separators for non-existent cells
		return tableView
	}()

	public init(style: UITableView.Style)
	{
		self.style = style
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	public override func loadView()
	{
		view = tableView
	}

	public override func viewDidLoad()
	{
		super.viewDidLoad()
	}

	public override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		coordinator?.didUpdateContentSize(tableView.contentSize)
	}

	public override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		// NOTE: Due to some SwiftUI bugs currently, we've chosen to call this here instead of actual parent call
		coordinator?.onMoveToParent()
	}

	public override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		// NOTE: Due to some SwiftUI bugs currently, we've chosen to call this here instead of actual parent call
		coordinator?.onMoveFromParent()
	}
}

@available(iOS 13.0, *)
class AS_UITableView: UITableView {}
