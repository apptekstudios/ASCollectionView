// ASCollectionView. Created by Apptek Studios 2019

import Combine
import Foundation

struct Item: Identifiable
{
	var id: Int
	var displayString: String
}

class TagStore: ObservableObject
{
	init()
	{}

	@Published var items: [Item] = TagStore.randomItems()

	func refreshStore()
	{
		items = TagStore.randomItems()
	}

	fileprivate static let allWords = ["thisisaveryverylongtagthatshouldrequiremorethanonelinetofit", "alias", "consequatur", "aut", "perferendis", "sit", "voluptatem", "accusantium", "doloremque", "aperiam", "eaque", "ipsa", "quae", "ab", "illo", "inventore", "veritatis", "et", "quasi", "architecto", "beatae", "vitae", "dicta", "sunt", "explicabo", "aspernatur", "aut", "maiores", "doloribus", "asperiores", "repellat"]

	static func randomItems() -> [Item]
	{
		TagStore.allWords.indices.shuffled()[0 ... Int.random(in: 8 ... 18)].map
		{
			Item(id: $0, displayString: TagStore.allWords[$0])
		}
	}
}
