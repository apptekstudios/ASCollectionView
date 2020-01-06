// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

struct StoryView: View
{
	var post: Post

	var body: some View
	{
		VStack
		{
			ASRemoteImageView(post.url)
				.aspectRatio(contentMode: .fill)
				.clipShape(Circle())
				.frame(width: 50, height: 50)
				.fixedSize()
			Text(post.username)
				.lineLimit(1)
				.font(.caption)
				.truncationMode(.tail)
		}
	}
}

struct StoryView_Previews: PreviewProvider
{
	static var previews: some View
	{
		StoryView(post: Post.randomPost(Int.random(in: 0 ... 1000), aspectRatio: 1))
	}
}
