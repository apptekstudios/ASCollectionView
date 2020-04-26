// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
@_functionBuilder
public struct ViewArrayBuilder
{
	public enum Wrapper: View
	{
		case empty
		case view(AnyView)
		case group([Wrapper])

		init<Content: View>(_ view: Content) {
			// If this is actually a wrapper (not a view, unwrap it...)
			if let wrapper = view as? Wrapper
			{
				self = wrapper
				return
			}
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

		// This type conforms to view to allow it to be passed into the C0/C1/C2/C3... buildBlocks - this allows using if statements correctly
		public typealias Body = Never
		public var body: Never { fatalError() }
	}

	public typealias Output = Wrapper

	public static func buildEither<Content: View>(first: Content) -> Output
	{
		Wrapper(first)
	}

	public static func buildEither<Content: View>(second: Content) -> Output
	{
		Wrapper(second)
	}

	public static func buildIf<Content: View>(_ item: Content?) -> Output
	{
		item.map { Wrapper($0) } ?? .empty
	}

	public static func buildIf(_ subgroup: Wrapper?) -> Output
	{
		subgroup ?? .empty
	}

	public static func buildBlock(_ subgroup: Wrapper) -> Output
	{
		subgroup
	}

	public static func buildBlock<C0: View>(_ item0: C0) -> Output
	{
		Wrapper(item0)
	}

	public static func buildBlock<C0: View>(_ item0: [C0]) -> Output
	{
		.group(item0.map { Wrapper($0) })
	}

	public static func buildBlock<C0: View, C1: View>(_ item0: C0, _ item1: C1) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1)])
	}

	public static func buildBlock<C0: View, CX: View>(_ header: C0, _ array: [CX]) -> Output
	{
		.group([Wrapper(header), .group(array.map { Wrapper($0) })])
	}

	public static func buildBlock<C0: View, CX: View, C1: View>(_ header: C0, _ array: [CX], _ footer: C1) -> Output
	{
		.group([Wrapper(header), .group(array.map { Wrapper($0) }), Wrapper(footer)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View>(_ item0: C0, _ item1: C1, _ item2: C2) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3), Wrapper(item4)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3), Wrapper(item4), Wrapper(item5)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3), Wrapper(item4), Wrapper(item5), Wrapper(item6)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3), Wrapper(item4), Wrapper(item5), Wrapper(item6), Wrapper(item7)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7, _ item8: C8) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3), Wrapper(item4), Wrapper(item5), Wrapper(item6), Wrapper(item7), Wrapper(item8)])
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7, _ item8: C8, _ item9: C9) -> Output
	{
		.group([Wrapper(item0), Wrapper(item1), Wrapper(item2), Wrapper(item3), Wrapper(item4), Wrapper(item5), Wrapper(item6), Wrapper(item7), Wrapper(item8), Wrapper(item9)])
	}
}
