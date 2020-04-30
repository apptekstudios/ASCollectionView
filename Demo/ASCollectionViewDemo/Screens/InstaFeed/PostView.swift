// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI

struct PostView: View
{
	@State var liked: Bool = false
	@State var bookmarked: Bool = false

	@State var captionExpanded: Bool = false

	@Environment(\.invalidateCellLayout) var invalidateCellLayout

	var post: Post

	var header: some View
	{
		HStack
		{
			ASRemoteImageView(post.usernamePhotoURL)
				.aspectRatio(contentMode: .fill)
				.frame(width: 40, height: 40)
				.clipShape(Circle())
				.padding(.leading)
			VStack(alignment: .leading)
			{
				Text(post.username).fontWeight(.bold)
				Text(post.location)
			}
			Spacer()
			Image(systemName: "ellipsis")
				.padding()
		}
		.fixedSize(horizontal: false, vertical: true)
	}

	var buttonBar: some View
	{
		HStack
		{
			Image(systemName: self.liked ? "heart.fill" : "heart")
				.renderingMode(.template)
				.foregroundColor(self.liked ? .red : Color(.label))
				.onTapGesture
			{
				self.liked.toggle()
			}
			Image(systemName: "bubble.right")
			Image(systemName: "paperplane")
			Spacer()
			Image(systemName: self.bookmarked ? "bookmark.fill" : "bookmark")
				.renderingMode(.template)
				.foregroundColor(self.bookmarked ? .yellow : Color(.label))
				.onTapGesture
			{
				self.bookmarked.toggle()
			}
		}
		.font(.system(size: 28))
		.padding()
		.fixedSize(horizontal: false, vertical: true)
	}

	var textContent: some View
	{
		VStack(alignment: .leading, spacing: 10)
		{
			Text("Liked by ") + Text("apptekstudios").fontWeight(.bold) + Text(" and ") + Text("others").fontWeight(.bold)
			Group
			{
				Text("\(post.username)   ").fontWeight(.bold) + Text(post.caption)
			}
			.lineLimit(self.captionExpanded ? nil : 2)
			.truncationMode(.tail)
			.onTapGesture
			{
				self.captionExpanded.toggle()
				self.invalidateCellLayout?(false)
			}
			Text("View all \(post.comments) comments").foregroundColor(Color(.systemGray))
		}
		.padding([.leading, .trailing])
		.frame(maxWidth: .infinity, alignment: .leading)
		.fixedSize(horizontal: false, vertical: true)
	}

	var body: some View
	{
		VStack
		{
			header
			ASRemoteImageView(post.url)
				.aspectRatio(post.aspectRatio, contentMode: .fill)
				.gesture(
					TapGesture(count: 2).onEnded
					{
						self.liked.toggle()
					}
				)
			buttonBar
			textContent
			Spacer()
		}
		.padding([.top, .bottom])
	}
}

struct PostView_Previews: PreviewProvider
{
	static var previews: some View
	{
		PostView(post: Post.randomPost(Int.random(in: 0 ... 1000), aspectRatio: 1))
	}
}
