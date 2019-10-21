

import Foundation
import Combine

struct Item: Identifiable {
    var id: Int
    var displayString: String
}

class TagStore: ObservableObject {
    init() {
    }
    @Published var items: [Item] = TagStore.randomItems()
    
    func refreshStore() {
        items = TagStore.randomItems()
    }
    
    fileprivate static let allWords = ["alias", "consequatur", "aut", "perferendis", "sit", "voluptatem", "accusantium", "doloremque", "aperiam", "eaque", "ipsa", "quae", "ab", "illo"]
    
    static func randomItems() -> [Item] {
        TagStore.allWords.indices.shuffled()[0...Int.random(in: 5...10)].map {
            Item(id: $0, displayString: TagStore.allWords[$0])
        }
    }
}

