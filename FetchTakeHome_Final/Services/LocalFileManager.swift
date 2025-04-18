//
//  LocalFileManager.swift
//  FetchTakeHome_Final
//
//  Created by Khanh Nguyen on 4/15/25.
//

import SwiftUI
import Foundation

class LocalFileManager {

	 static let instance = LocalFileManager()
	 private let fileManager = FileManager.default
	 private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
	 private init() {}

	 func saveImage(from urlString: String?, for uuid: String) async throws {
			guard let urlString = urlString, let url = URL(string: urlString) else {
				 print("Invalid or missing URL for uuid: \(uuid)")
				 return
			}

			let fileURL = cacheDirectory.appendingPathComponent("\(uuid).jpg")

				 // Check if the image already exists
			if FileManager.default.fileExists(atPath: fileURL.path) {
				 print("Image already exists for uuid: \(uuid), skipping download")
				 return
			}

			let (data, _) = try await URLSession.shared.data(from: url)
			print("Downloading Image \(uuid)")
			try data.write(to: fileURL)

	 }
	 func retrieveImages(for uuid: String) -> UIImage? {
			let fileURL = cacheDirectory.appendingPathComponent("\(uuid).jpg")
			print("Retreiving File Manager Image: \(uuid)")
			guard FileManager.default.fileExists(atPath: fileURL.path),
						let image = UIImage(contentsOfFile: fileURL.path) else {
				 print("Error Retrieving Image from File Manager: \(uuid)")
				 return nil
			}
			return image
	 }

	 func deleteAllImages() throws {
			let files = try fileManager.contentsOfDirectory(atPath: cacheDirectory.path())
			for file in files where file.hasSuffix(".jpg") {
				 let fileURL = cacheDirectory.appendingPathComponent(file)
				 try fileManager.removeItem(at: fileURL)
				 print("Deleted image: \(file)")
			}
	 }
}


