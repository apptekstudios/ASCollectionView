// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public protocol Nestable
{
	associatedtype T
	func asArray() -> [T]
}

@available(iOS 13.0, *)
extension ASSection: Nestable
{
	public func asArray() -> [ASSection]
	{
		[self]
	}
}

@available(iOS 13.0, *)
extension Optional: Nestable where Wrapped: Nestable
{
	public func asArray() -> [Wrapped.T]
	{
		map { $0.asArray() } ?? []
	}
}

@available(iOS 13.0, *)
extension Array: Nestable
{
	public func asArray() -> Self
	{
		self
	}
}

@available(iOS 13.0, *)
public func buildSectionArray<SectionID: Hashable>(@SectionArrayBuilder <SectionID> _ sections: () -> [ASSection<SectionID>]) -> [ASSection<SectionID>]
{
	sections()
}

@available(iOS 13.0, *)
@_functionBuilder
public struct SectionArrayBuilder<SectionID> where SectionID: Hashable
{
	public typealias Section = ASCollectionViewSection<SectionID>
	public typealias Output = [Section]

	public static func buildEither<C0: Nestable>(first: C0) -> Output where C0.T == Section
	{
		first.asArray()
	}

	public static func buildEither<C0: Nestable>(second: C0) -> Output where C0.T == Section
	{
		second.asArray()
	}

	public static func buildIf<C0: Nestable>(_ item: C0?) -> Output where C0.T == Section
	{
		item.map { $0.asArray() } ?? []
	}

	public static func buildBlock<C0: Nestable>(_ section: C0) -> Output where C0.T == Section
	{
		section.asArray()
	}

	public static func buildBlock<C0: Nestable, C1: Nestable>(_ item0: C0, _ item1: C1) -> Output where C0.T == Section, C1.T == Section
	{
		[item0.asArray(), item1.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2) -> Output where C0.T == Section, C1.T == Section, C2.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable, C4: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section, C4.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray(), item4.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable, C4: Nestable, C5: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section, C4.T == Section, C5.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray(), item4.asArray(), item5.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable, C4: Nestable, C5: Nestable, C6: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section, C4.T == Section, C5.T == Section, C6.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray(), item4.asArray(), item5.asArray(), item6.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable, C4: Nestable, C5: Nestable, C6: Nestable, C7: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section, C4.T == Section, C5.T == Section, C6.T == Section, C7.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray(), item4.asArray(), item5.asArray(), item6.asArray(), item7.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable, C4: Nestable, C5: Nestable, C6: Nestable, C7: Nestable, C8: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7, _ item8: C8) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section, C4.T == Section, C5.T == Section, C6.T == Section, C7.T == Section, C8.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray(), item4.asArray(), item5.asArray(), item6.asArray(), item7.asArray(), item8.asArray()].flatMap { $0 }
	}

	public static func buildBlock<C0: Nestable, C1: Nestable, C2: Nestable, C3: Nestable, C4: Nestable, C5: Nestable, C6: Nestable, C7: Nestable, C8: Nestable, C9: Nestable>(_ item0: C0, _ item1: C1, _ item2: C2, _ item3: C3, _ item4: C4, _ item5: C5, _ item6: C6, _ item7: C7, _ item8: C8, _ item9: C9) -> Output where C0.T == Section, C1.T == Section, C2.T == Section, C3.T == Section, C4.T == Section, C5.T == Section, C6.T == Section, C7.T == Section, C8.T == Section, C9.T == Section
	{
		[item0.asArray(), item1.asArray(), item2.asArray(), item3.asArray(), item4.asArray(), item5.asArray(), item6.asArray(), item7.asArray(), item8.asArray(), item9.asArray()].flatMap { $0 }
	}
}
