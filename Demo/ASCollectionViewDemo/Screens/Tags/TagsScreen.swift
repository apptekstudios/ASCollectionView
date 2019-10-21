
import SwiftUI
import ASCollectionView

struct TagsScreen: View {
    @ObservedObject var store = TagStore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                Text("Tap screen to reload new tags")
                    .padding()
                    .background(Color(.secondarySystemBackground))
                Spacer()
            }
            Text("Tags:")
                .font(.title)
            ASCollectionView(
                data: store.items,
                layout: .init(layout: {
                    let fl = AlignedFlowLayout()
                    fl.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
                    return fl
                }())
            ) { item in
                Text(item.displayString)
                    .fixedSize()
                    .padding(5)
                    .background(Color(.systemGray))
                    .cornerRadius(5)
            }
        }
        .padding()
        .onTapGesture {
            self.store.refreshStore()
        }
        
    }
}

class AlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            guard layoutAttribute.representedElementCategory == .cell else {
                return
            }
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }
        
        return attributes
    }
}

struct TagsScreen_Previews: PreviewProvider {
    static var previews: some View {
        TagsScreen()
    }
}
