// ASCollectionView. Created by Apptek Studios 2019

import Foundation

struct ASIndexedDictionary<Key: Hashable, Value>: BidirectionalCollection
{
	private var dictionary: [Key: Int] = [:]
	private var array: [Value] = []

	mutating func append(_ item: (key: Key, value: Value))
	{
		if let index = dictionary[item.key]
		{
			array.remove(at: index)
		}
		array.append(item.value)
		dictionary[item.key] = array.endIndex - 1
	}

	mutating func append(_ items: [(key: Key, value: Value)])
	{
		items.forEach { append($0) }
	}

	mutating func removeAll()
	{
		dictionary.removeAll()
		array.removeAll()
	}

	var startIndex: Int { array.startIndex }

	var endIndex: Int { array.endIndex }

	var lastIndex: Int { Swift.max(startIndex, endIndex - 1) }

	func index(before i: Int) -> Int
	{
		array.index(before: i)
	}

	func index(after i: Int) -> Int
	{
		array.index(after: i)
	}

	subscript(index: Int) -> Value
	{
		array[index]
	}

	subscript(_ key: Key) -> Value?
	{
		get
		{
			dictionary[key].map { array[$0] }
		}
		set
		{
			guard let newValue = newValue else
			{
				_ = dictionary[key].map { array.remove(at: $0) }
				return
			}
			if let index = dictionary[key]
			{
				array[index] = newValue
			}
			else
			{
				append((key, value: newValue))
			}
		}
	}
}
