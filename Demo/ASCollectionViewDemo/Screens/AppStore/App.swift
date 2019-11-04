// ASCollectionView. Created by Apptek Studios 2019

import Foundation

struct App: Identifiable
{
	var appName: String
	var caption: String

	var randomNumberForImage: Int

	var featureImageURL: URL
	{
		URL(string: "https://picsum.photos/800/500?random=\(abs(randomNumberForImage))")!
	}

	var squareThumbURL: URL
	{
		URL(string: "https://picsum.photos/500?random=\(abs(randomNumberForImage))")!
	}

	var id: Int
	{
		randomNumberForImage.hashValue
	}

	static func randomApp(_ randomNumber: Int) -> App
	{
		App(
			appName: Lorem.title,
			caption: Lorem.caption,
			randomNumberForImage: randomNumber)
	}
}
