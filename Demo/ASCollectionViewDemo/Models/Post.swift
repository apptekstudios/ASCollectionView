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

	static func randomPost(_ randomNumber: Int, aspectRatio: CGFloat) -> Post
	{
		Post(username: Lorem.fullName,
		     location: Lorem.words(Int.random(in: 1...3)),
		     caption: Lorem.sentences(1...3),
		     aspectRatio: aspectRatio,
		     randomNumberForImage: randomNumber)
	}
}
