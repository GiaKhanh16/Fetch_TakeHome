import Observation
import Foundation
import SwiftUI

@Observable
class NetWorking {
	 var recipes: [Recipe] = []
	 var errorMessage: String? = nil 
	 var fileManager = LocalFileManager.instance

	 func fetchData() async throws {
			await MainActor.run {
				 self.errorMessage = nil
			}

			try await Task.sleep(nanoseconds: 1_000_000_000)

			guard let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes-malformed.json") else {
				 self.errorMessage = "Invalid URL. Please try again later."
				 throw NetworkError.invalidURL
			}

			let (data, response) = try await URLSession.shared.data(from: url)

			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				 self.errorMessage = "Server error (status \(httpResponse.statusCode)). Please try again."
				 throw NetworkError.httpError(statusCode: httpResponse.statusCode)
			}

			do {
				 let decodedResponse = try JSONDecoder().decode(RecipeResponse.self, from: data)
				 for recipe in decodedResponse.recipes {
						if recipe.cuisine.isEmpty || recipe.name.isEmpty || recipe.uuid.isEmpty {
							 print("Malformed recipe detected: \(recipe)")
							 self.errorMessage = "Invalid recipe data received. Please try again."
							 throw NetworkError.decodingError
						}
				 }
			}
			catch {
				 print("This data is malformed")
			}

			do {
				 let decodedResponse = try JSONDecoder().decode(RecipeResponse.self, from: data)

				 await MainActor.run {
						self.recipes = decodedResponse.recipes
				 }

				 for recipe in decodedResponse.recipes {
							 // Check if the image is already cached
						if fileManager.retrieveImages(for: recipe.uuid) == nil {
							 print("Caching Images From The Network")
							 try await fileManager.saveImage(from: recipe.photoUrlSmall, for: recipe.uuid)
						} else {
							 print("Image already cached for uuid: \(recipe.uuid), skipping download")
						}
				 }
			}
			catch {
				 let errorDescription = error.localizedDescription
				 print("Error fetching data: \(errorDescription)")
				 self.errorMessage = "Failed to load recipes. Please try again."
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
