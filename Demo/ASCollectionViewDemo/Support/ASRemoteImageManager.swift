// ASCollectionView. Created by Apptek Studios 2019

import Combine
import Foundation
import UIKit

class ASRemoteImageManager
{
	static let shared = ASRemoteImageManager()
	private init() {}

	let cache = ASCache<URL, ASRemoteImageLoader>()

	func load(_ url: URL)
	{
		imageLoader(for: url).start()
	}

	func cancelLoad(for url: URL)
	{
		imageLoader(for: url).cancel()
	}

	func imageLoader(for url: URL) -> ASRemoteImageLoader
	{
		if let existing = cache.value(forKey: url)
		{
			return existing
		}
		else
		{
			let loader = ASRemoteImageLoader(url)
			cache.setValue(loader, forKey: url)
			return loader
		}
	}
}

class ASRemoteImageLoader: ObservableObject
{
	var url: URL

	@Published
	var state: State?
	{
		didSet
		{
			DispatchQueue.main.async
			{
				self.stateDidChange.send()
			}
		}
	}

	public let stateDidChange = PassthroughSubject<Void, Never>()

	init(_ url: URL)
	{
		self.url = url
	}

	enum State
	{
		case loading
		case success(UIImage)
		case failed
	}

	private var cancellable: AnyCancellable?

	var image: UIImage?
	{
		switch state
		{
		case let .success(image):
			return image
		default:
			return nil
		}
	}

	func start()
	{
		guard state == nil else
		{
			return
		}
		DispatchQueue.main.async
		{
			self.state = .loading
		}

		cancellable = URLSession.shared.dataTaskPublisher(for: url)
			.map { UIImage(data: $0.data) }
			.replaceError(with: nil)
			.receive(on: DispatchQueue.main)
			.sink
		{ image in
			if let image = image
			{
				self.state = .success(image)
			}
			else
			{
				self.state = .failed
			}
		}
	}

	func cancel()
	{
		cancellable?.cancel()
		cancellable = nil
		guard case .success = state else
		{
			DispatchQueue.main.async
			{
				self.state = nil
			}
			return
		}
	}
}
