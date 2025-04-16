	 //
	 //  Networking.swift
	 //  FetchTakeHome_Final
	 //
	 //  Created by Khanh Nguyen on 4/15/25.
	 //

import Observation
import Foundation
import SwiftUI


@Observable
class NetWorking {
	 var recipes: [Recipe] = []
	 var fileManager = LocalFileManager.instance

	 

	 func fetchData() async throws {
			guard let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json") else {
				 print("Invalid URL")
				 return
			}
			let (data, response) = try await URLSession.shared.data(from: url)

			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				 throw URLError(.badServerResponse)
			}

			do {
				 let decodedResponse = try JSONDecoder().decode(RecipeResponse.self, from: data)
				 recipes = decodedResponse.recipes
				 for recipe in decodedResponse.recipes {
						try await fileManager.saveImage(from: recipe.photoUrlSmall, for: recipe.uuid)
				 }

			} catch {
				 throw NetworkError.decodingError
			}
	 }
}

enum NetworkError: Error {
	 case invalidURL
	 case httpError(statusCode: Int)
	 case decodingError
}

struct Recipe: Identifiable, Codable {
	 let cuisine: String
	 let name: String
	 let photoUrlLarge: String?
	 let photoUrlSmall: String?
	 let uuid: String
	 let sourceUrl: String?
	 let youtubeUrl: String?

	 var id: String { uuid }

	 enum CodingKeys: String, CodingKey {
			case cuisine
			case name
			case photoUrlLarge = "photo_url_large"
			case photoUrlSmall = "photo_url_small"
			case uuid
			case sourceUrl = "source_url"
			case youtubeUrl = "youtube_url"
	 }
}

struct RecipeResponse: Codable {
	 let recipes: [Recipe]
}
