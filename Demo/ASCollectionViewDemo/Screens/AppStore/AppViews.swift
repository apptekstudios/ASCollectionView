// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

struct GetButton: View
{
	var body: some View
	{
		Button(action: {
			// Do something
		})
		{
			Text("GET")
				.fontWeight(.bold)
				.padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
		}
		.background(Capsule().fill(Color(.systemGray6)))
	}
}

struct AppViewFeature: View
{
	var app: App
	var body: some View
	{
		VStack(alignment: .leading)
		{
			Text(app.appName)
				.font(.headline)
				.lineLimit(1)
			Text(app.caption)
				.font(.body)
				.foregroundColor(.secondary)
				.lineLimit(2)
			ASRemoteImageView(app.featureImageURL)
				.cornerRadius(16)
				.clipped()
		}
	}
}

struct AppViewLarge: View
{
	var app: App
	var body: some View
	{
		HStack(alignment: .top)
		{
			ASRemoteImageView(app.squareThumbURL)
				.aspectRatio(1, contentMode: .fit)
				.cornerRadius(16)
				.clipped()
			VStack(alignment: .leading)
			{
				Text(app.appName)
					.font(.headline)
				Text(app.caption)
					.font(.caption)
					.foregroundColor(.secondary)
				Spacer()
				GetButton()
			}
			Spacer()
		}
	}
}

struct AppViewCompact: View
{
	var app: App
	var body: some View
	{
		HStack(alignment: .center)
		{
			ASRemoteImageView(app.squareThumbURL)
				.aspectRatio(1, contentMode: .fit)
				.cornerRadius(16)
				.clipped()
			VStack(alignment: .leading)
			{
				Text(app.appName)
					.font(.headline)
					.lineLimit(1)
				Text(app.caption)
					.font(.caption)
					.foregroundColor(.secondary)
					.lineLimit(2)
			}
			Spacer()
			GetButton()
		}
	}
}

struct NumberView_Previews: PreviewProvider
{
	static var previews: some View
	{
		Group
		{
			AppViewFeature(app: App.randomApp(1))
				.previewLayout(.fixed(width: 400, height: 300))

			AppViewLarge(app: App.randomApp(1))
				.previewLayout(.fixed(width: 400, height: 125))

			AppViewCompact(app: App.randomApp(1))
				.previewLayout(.fixed(width: 400, height: 83))
		}
	}
}
