// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
@_functionBuilder
public struct ViewArrayBuilder
{
	public enum Wrapper
	{
		case empty
		case view(AnyView)
		case group([Wrapper])

		init<Content: View>(_ view: Content) {
			self = .view(AnyView(view))
		}

		func flattened() -> [AnyView]
		{
			switch self
			{
			case .empty:
				return []
			case let .view(theView):
				return [theView]
			case let .group(wrappers):
				return wrappers.flatMap { $0.flattened() }
			}
		}
	}

	public typealias Output = Wrapper

	public static func buildExpression<Content: View>(_ view: Content?) -> Wrapper
	{
		view.map { Wrapper($0) } ?? .empty
	}

	public static func buildExpression<Content: View>(_ views: [Content]?) -> Wrapper
	{
		guard let views = views else { return .empty }
		return Wrapper.group(views.map { Wrapper($0) })
	}

	public static func buildEither(first: Wrapper) -> Output
	{
		first
	}

	public static func buildEither(second: Wrapper) -> Output
	{
		second
	}

	public static func buildIf(_ item: Wrapper?) -> Output
	{
		item ?? .empty
	}

	public static func buildBlock(_ item0: Wrapper) -> Output
	{
		item0
	}

	public static func buildBlock(_ items: Wrapper...) -> Output
	{
		.group(items)
	}
}
