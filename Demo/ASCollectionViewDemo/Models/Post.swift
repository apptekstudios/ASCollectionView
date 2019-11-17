// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

struct Post: Identifiable
{
	var username: String
	var location: String
	var caption: String
	var aspectRatio: CGFloat
	var randomNumberForImage: Int
	var offset: Int

	var url: URL
	{
		URL(string: "https://picsum.photos/\(Int(aspectRatio * 500))/500?random=\(abs(randomNumberForImage))")!
	}

	var squareThumbURL: URL
	{
		URL(string: "https://picsum.photos/500?random=\(abs(randomNumberForImage))")!
	}

	var usernamePhotoURL: URL = URL(string: "https://picsum.photos/100?random=\(Int.random(in: 0...500))")!
	var comments: Int = .random(in: 4...600)

	var id: Int
	{
		randomNumberForImage.hashValue
	}

	static func randomPost(_ randomNumber: Int, aspectRatio: CGFloat, offset: Int = 0) -> Post
	{
		Post(
			username: Lorem.fullName,
			location: Lorem.words(Int.random(in: 1...3)),
			caption: Lorem.sentences(1...3),
			aspectRatio: aspectRatio,
			randomNumberForImage: randomNumber,
			offset: offset)
	}
}

struct DataSource
{
	static func postsForGridSection(_ sectionID: Int, number: Int = 12) -> [Post]
	{
		(0..<number).map
		{ b -> Post in
			let aspect: CGFloat = 1
			return Post.randomPost(sectionID * 10_000 + b, aspectRatio: aspect, offset: b)
		}
	}

	static func postsForInstaSection(_ sectionID: Int, number: Int = 12) -> [Post]
	{
		(0..<number).map
		{ b -> Post in
			let aspect: CGFloat = [0.75, 1.0, 1.5].randomElement() ?? 1
			return Post.randomPost(sectionID * 10_000 + b, aspectRatio: aspect, offset: b)
		}
	}

	static func postsForWaterfallSection(_ sectionID: Int, number: Int = 12) -> [Post]
	{
		(0..<number).map
		{ b -> Post in
			let aspect: CGFloat = .random(in: 0.3...1.5)
			return Post.randomPost(sectionID * 10_000 + b, aspectRatio: aspect, offset: b)
		}
	}

	static func appsForSection(_ sectionID: Int) -> [App]
	{
		(0...17).map
		{ b -> App in
			App.randomApp(sectionID * 10_000 + b)
		}
	}
}
