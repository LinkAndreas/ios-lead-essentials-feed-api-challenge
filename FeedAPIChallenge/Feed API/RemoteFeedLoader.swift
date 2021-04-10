//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	private enum Constants {
		static let OK_200: UInt = 200
	}

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard let self = self else { return }

			switch result {
			case let .success((data, response)) where response.statusCode == Constants.OK_200:
				completion(self.handleSuccessfulResponseWithStatusCode200(data: data))

			case .success:
				completion(.failure(Error.invalidData))

			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private func handleSuccessfulResponseWithStatusCode200(data: Data) -> FeedLoader.Result {
		do {
			let root: Root = try JSONDecoder().decode(Root.self, from: data)
			return .success(FeedImageMapper.map(from: root.items))
		} catch {
			return .failure(Error.invalidData)
		}
	}
}

private enum FeedImageMapper {
	static func map(from entities: [FeedImageEntity]) -> [FeedImage] {
		return entities.map(map(from:))
	}

	static func map(from entity: FeedImageEntity) -> FeedImage {
		return .init(
			id: entity.id,
			description: entity.description,
			location: entity.location,
			url: entity.url
		)
	}
}

private struct Root: Decodable {
	let items: [FeedImageEntity]
}
