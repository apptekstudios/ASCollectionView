// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

struct MainView: View
{
	var body: some View
	{
		TabView
		{
			FeedView()
				.tabItem
			{
				Image(systemName: "1.square.fill")
				Text("Feed")
			}
			GridView()
				.tabItem
			{
				Image(systemName: "2.square.fill")
				Text("Explore")
			}
			OrthoView()
				.tabItem
			{
				Image(systemName: "3.square.fill")
				Text("Store")
			}
		}
	}
}

struct MainView_Previews: PreviewProvider
{
	static var previews: some View
	{
		MainView()
	}
}
