// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@_functionBuilder
public struct SectionArrayBuilder<SectionID> where SectionID: Hashable
{
	public typealias Section = ASCollectionViewSection<SectionID>
	public typealias Output = [Section]

	public static func buildBlock(_ section: Section) -> Output
	{
		[section]
	}

	public static func buildBlock(_ sections: Section...) -> Output
	{
		sections
	}

	public static func buildEither(first: Section) -> Output
	{
		[first]
	}

	public static func buildEither(second: Section) -> Output
	{
		[second]
	}

	public static func buildIf(_ item: Section?) -> Output
	{
		[item].compactMap { $0 }
	}
}
