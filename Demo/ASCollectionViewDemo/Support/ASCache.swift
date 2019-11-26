// ASCollectionView. Created by Apptek Studios 2019

import Foundation

final class ASCache<Key: Hashable, Value>
{
	private let wrappedCache = NSCache<WrappedKey, Entry>()
	private let keyTracker = KeyTracker()

	private let entryLifetime: TimeInterval?

	init(entryLifetime: TimeInterval? = nil)
	{
		self.entryLifetime = entryLifetime
		wrappedCache.delegate = keyTracker
	}

	subscript(_ key: Key) -> Value?
	{
		get { value(forKey: key) }
		set { setValue(newValue, forKey: key) }
	}

	func setValue(_ value: Value?, forKey key: Key)
	{
		guard let value = value else
		{
			removeValue(forKey: key)
			return
		}
		let expirationDate = entryLifetime.map { Date().addingTimeInterval($0) }
		let entry = Entry(key: key, value: value, expirationDate: expirationDate)
		setEntry(entry)
	}

	func value(forKey key: Key) -> Value?
	{
		entry(forKey: key)?.value
	}

	func removeValue(forKey key: Key)
	{
		wrappedCache.removeObject(forKey: WrappedKey(key))
	}
}

private extension ASCache
{
	func entry(forKey key: Key) -> Entry?
	{
		guard let entry = wrappedCache.object(forKey: WrappedKey(key)) else
		{
			return nil
		}

		guard !entry.hasExpired else
		{
			removeValue(forKey: key)
			return nil
		}

		return entry
	}

	func setEntry(_ entry: Entry)
	{
		wrappedCache.setObject(entry, forKey: WrappedKey(entry.key))
		keyTracker.keys.insert(entry.key)
	}
}

private extension ASCache
{
	final class KeyTracker: NSObject, NSCacheDelegate
	{
		var keys = Set<Key>()

		func cache(
			_ cache: NSCache<AnyObject, AnyObject>,
			willEvictObject object: Any)
		{
			guard let entry = object as? Entry else
			{
				return
			}

			keys.remove(entry.key)
		}
	}
}

private extension ASCache
{
	final class WrappedKey: NSObject
	{
		let key: Key

		init(_ key: Key) { self.key = key }

		override var hash: Int { key.hashValue }

		override func isEqual(_ object: Any?) -> Bool
		{
			guard let value = object as? WrappedKey else
			{
				return false
			}

			return value.key == key
		}
	}

	final class Entry
	{
		let key: Key
		let value: Value
		let expirationDate: Date?

		var hasExpired: Bool
		{
			if let expirationDate = expirationDate
			{
				// Discard values that have expired
				return Date() >= expirationDate
			}
			return false
		}

		init(key: Key, value: Value, expirationDate: Date? = nil)
		{
			self.key = key
			self.value = value
			self.expirationDate = expirationDate
		}
	}
}

extension ASCache.Entry: Codable where Key: Codable, Value: Codable {}

extension ASCache: Codable where Key: Codable, Value: Codable
{
	convenience init(from decoder: Decoder) throws
	{
		self.init()

		let container = try decoder.singleValueContainer()
		let entries = try container.decode([Entry].self)
		// Only load non-expired entries
		entries.filter { !$0.hasExpired }.forEach(setEntry)
	}

	func encode(to encoder: Encoder) throws
	{
		// Only save non-expired entries
		let currentEntries = keyTracker.keys.compactMap(entry).filter { !$0.hasExpired }
		var container = encoder.singleValueContainer()
		try container.encode(currentEntries)
	}
}
