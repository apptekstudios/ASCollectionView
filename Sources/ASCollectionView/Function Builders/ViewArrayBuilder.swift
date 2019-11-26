// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@_functionBuilder
public struct ViewArrayBuilder
{
	public typealias Output = [AnyView]

	public static func buildEither<Content: View>(first: Content) -> Output
	{
		[AnyView(first)]
	}

	public static func buildEither<Content: View>(second: Content) -> Output
	{
		[AnyView(second)]
	}

	public static func buildIf<Content: View>(_ item: Content?) -> Output
	{
		[item].compactMap { $0.map(AnyView.init) }
	}

	public static func buildBlock<C0: View>(_ item0: C0) -> Output
	{
		[AnyView(item0)]
	}

	public static func buildBlock<C0: View>(_ item0: [C0]) -> Output
	{
		item0.map(AnyView.init)
	}

	public static func buildBlock(_ item0: [AnyView]) -> Output
	{
		item0
	}

	public static func buildBlock<C0: View, C1: View>(_ item0: C0, _ item1: C1) -> Output
	{
		[AnyView(item0), AnyView(item1)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View>(_ item0: C0, _ item1: C1, _ item2: C2) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3), AnyView(item4)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3), AnyView(item4), AnyView(item5)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3), AnyView(item4), AnyView(item5), AnyView(item6)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3), AnyView(item4), AnyView(item5), AnyView(item6), AnyView(item7)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7, _ item8: C8) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3), AnyView(item4), AnyView(item5), AnyView(item6), AnyView(item7), AnyView(item8)]
	}

	public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7, _ item8: C8, _ item9: C9) -> Output
	{
		[AnyView(item0), AnyView(item1), AnyView(item2), AnyView(item3), AnyView(item4), AnyView(item5), AnyView(item6), AnyView(item7), AnyView(item8), AnyView(item9)]
	}
}
