// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI

struct TagsScreen: View
{
	@ObservedObject var store = TagStore()

	/// Used in the extra example that shrinks the collectionView to fit its content
	var shrinkToSize: Bool = false
	@State var contentSize: CGSize? // This state variable is handed to the collectionView to allow it to store the content size
	///

	var body: some View
	{
		VStack(alignment: .leading, spacing: 20)
		{
			HStack
			{
				Spacer()
				Text("Tap screen to reload new tags")
					.padding()
					.background(Color(.secondarySystemBackground))
				Spacer()
			}
			Text("Tags:")
				.font(.title)

			ASCollectionView(
				section:
				ASCollectionViewSection(id: 0, data: store.items)
				{ item, _ in
					Text(item.displayString)
						.fixedSize()
						.padding(5)
						.background(Color(.systemGray))
						.cornerRadius(5)
			})
				.layout
			{
				let fl = AlignedFlowLayout()
				fl.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
				return fl
			}
			.shrinkToContentSize(isEnabled: shrinkToSize, $contentSize, dimensionToShrink: .vertical)

			if shrinkToSize
			{
				Rectangle().fill(Color(.secondarySystemBackground))
					.overlay(
						Text("This is another view in the VStack, it shows how the collectionView above fits itself to the content.")
							.foregroundColor(Color(.secondaryLabel))
							.padding(),
						alignment: .topLeading)
			}
		}
		.padding()
		.onTapGesture
		{
			self.store.refreshStore()
		}
		.navigationBarTitle("Tags", displayMode: .inline)
	}
}

class AlignedFlowLayout: UICollectionViewFlowLayout
{
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
	{
		if let collectionView = self.collectionView
		{
			return collectionView.frame.width != newBounds.width // We only care about changes in the width
		}

		return false
	}

	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
	{
		let attributes = super.layoutAttributesForElements(in: rect)

		attributes?.forEach
		{ layoutAttribute in
			guard layoutAttribute.representedElementCategory == .cell else
			{
				return
			}
			layoutAttributesForItem(at: layoutAttribute.indexPath).map { layoutAttribute.frame = $0.frame }
		}

		return attributes
	}

	private var leftEdge: CGFloat
	{
		guard let insets = collectionView?.adjustedContentInset else
		{
			return sectionInset.left
		}
		return insets.left + sectionInset.left
	}

	private var contentWidth: CGFloat?
	{
		guard let collectionViewWidth = collectionView?.frame.size.width,
			let insets = collectionView?.adjustedContentInset else
		{
			return nil
		}
		return collectionViewWidth - insets.left - insets.right - sectionInset.left - sectionInset.right
	}

	fileprivate func isFrame(for firstItemAttributes: UICollectionViewLayoutAttributes, inSameLineAsFrameFor secondItemAttributes: UICollectionViewLayoutAttributes) -> Bool
	{
		guard let lineWidth = contentWidth else
		{
			return false
		}
		let firstItemFrame = firstItemAttributes.frame
		let lineFrame = CGRect(
			x: leftEdge,
			y: firstItemFrame.origin.y,
			width: lineWidth,
			height: firstItemFrame.size.height)
		return lineFrame.intersects(secondItemAttributes.frame)
	}

	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
	{
		guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else
		{
			return nil
		}
		guard attributes.representedElementCategory == .cell else
		{
			return attributes
		}
		guard
			indexPath.item > 0,
			let previousAttributes = self.layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1, section: indexPath.section))
		else
		{
			attributes.frame.origin.x = leftEdge // first item of the section should always be left aligned
			return attributes
		}

		if isFrame(for: attributes, inSameLineAsFrameFor: previousAttributes)
		{
			attributes.frame.origin.x = previousAttributes.frame.maxX + minimumInteritemSpacing
		}
		else
		{
			attributes.frame.origin.x = leftEdge
		}

		return attributes
	}
}

struct TagsScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		TagsScreen()
	}
}
