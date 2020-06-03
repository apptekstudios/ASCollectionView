// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI

struct TagsScreen: View
{
	@ObservedObject var store = TagStore()

	var body: some View
	{
		ScrollView(.vertical) {
			VStack(alignment: .leading, spacing: 20)
			{
				Text("This screen has an ASCollectionView embedded into a SwiftUI scrollview")
					.multilineTextAlignment(.center)
					.fixedSize(horizontal: false, vertical: true)
					.frame(maxWidth: .infinity)
					.padding()
				HStack
				{
					Spacer()
					Text("Tap this button to reload new tags")
						.padding()
						.background(Color(.secondarySystemBackground))
					Spacer()
				}
				.onTapGesture
				{
					self.store.refreshStore()
				}
				Text("Tags:")
					.font(.title)

				ASCollectionView(
					section:
					ASCollectionViewSection(id: 0, data: store.items)
					{ item, _ in
						Text(item.displayString)
							.fixedSize(horizontal: false, vertical: true)
							.padding(5)
							.background(Color(.systemGray))
							.cornerRadius(5)
					}.selfSizingConfig { _ in
						ASSelfSizingConfig(canExceedCollectionWidth: false)
					}
				)
				.layout
				{
					let fl = AlignedFlowLayout()
					fl.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
					return fl
				}
				.fitContentSize(dimension: .vertical)
				Text("This is another view in the VStack, it shows how the collectionView above fits itself to the content.")
					.padding()
					.frame(maxWidth: .infinity)
					.foregroundColor(Color(.secondaryLabel))
					.fixedSize(horizontal: false, vertical: true)
					.background(Color(.secondarySystemBackground))
			}
			.padding()
		}
		.navigationBarTitle("Tags", displayMode: .inline)
	}
}

class AlignedFlowLayout: UICollectionViewFlowLayout
{
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
	{
		true
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
			let previousAttributes = layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1, section: indexPath.section))
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
