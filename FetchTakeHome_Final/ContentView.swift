import SwiftUI

struct ContentView: View {
	 @State var netWorking = NetWorking() // Changed to @StateObject for proper lifecycle management
	 @State private var searchText = ""
	 @State private var showAlert = false
	 @State private var selectedURL: URL?
	 @State private var sortOrder: SortOrder = .nameAscending
	 @State private var isLoading = false // Added to track loading state
	 var fileManager = LocalFileManager.instance

	 var body: some View {
			NavigationStack {
				 Group {
						if isLoading {
									// Loading state
							 ProgressView("Loading recipes...")
									.frame(maxWidth: .infinity, maxHeight: .infinity)
						} else if netWorking.recipes.isEmpty && searchText.isEmpty {
									// Empty state for no recipes
							 VStack {
									Image(systemName: "tray.fill")
										 .resizable()
										 .scaledToFit()
										 .frame(width: 100, height: 100)
										 .foregroundColor(.gray)
										 .padding(.bottom, 20)
									Text("Error Loading Recipes")
										 .font(.title2)
										 .fontWeight(.bold)
										 .foregroundColor(.gray)
									Text("It looks like there are no recipes to display at the moment.")
										 .font(.subheadline)
										 .foregroundColor(.gray)
										 .multilineTextAlignment(.center)
										 .padding(.horizontal)
							 }
							 .frame(maxWidth: .infinity, maxHeight: .infinity)
							 .offset(y: -100)
						} else {
									// Main content with recipe list
							 List {
									ForEach(groupedRecipes.keys.sorted(), id: \.self) { cuisine in
										 Section(header: Text(cuisine).font(.title2).fontWeight(.bold)) {
												ForEach(groupedRecipes[cuisine]!) { recipe in
													 HStack {
															if let uiImage = fileManager.retrieveImages(for: recipe.uuid) {
																 Image(uiImage: uiImage)
																		.resizable()
																		.scaledToFill()
																		.frame(width: 60, height: 60)
																		.clipShape(RoundedRectangle(cornerRadius: 8))
															}

															VStack(alignment: .leading) {
																 Text(recipe.name)
																		.font(.headline)
																 Text(recipe.cuisine)
																		.font(.subheadline)
																		.foregroundColor(.secondary)
															}
													 }
													 .contentShape(Rectangle())
													 .onTapGesture {
															if let urlString = recipe.youtubeUrl, let url = URL(string: urlString) {
																 selectedURL = url
																 showAlert = true
															}
													 }
												}
										 }
									}
							 }
							 .background {
										 // Empty state for no search results
									if filteredRecipes.isEmpty && !searchText.isEmpty {
										 VStack {
												Image(systemName: "fork.knife")
													 .resizable()
													 .scaledToFit()
													 .frame(width: 100, height: 100)
													 .foregroundColor(.gray)
													 .padding(.bottom, 20)
												Text("No Recipes Found")
													 .font(.title2)
													 .foregroundColor(.gray)
										 }
										 .frame(maxWidth: .infinity, maxHeight: .infinity)
									}
							 }
						}
				 }
				 .refreshable {

						do {
							 try await netWorking.fetchData()
//						try	 fileManager.deleteAllImages()
						} catch {
							 print("Error refreshing data: \(error)")
						}

				 }
				 .navigationTitle("Cuisine")
				 .listStyle(.plain)
				 .searchable(text: $searchText, prompt: "Search recipes")
				 .toolbar {
						ToolbarItem(placement: .topBarTrailing) {
							 Menu {
									Picker("Sort", selection: $sortOrder) {
										 ForEach(SortOrder.allCases) { option in
												Text(option.rawValue).tag(option)
										 }
									}
									.pickerStyle(.inline)
							 } label: {
									Label("Sort", systemImage: "arrow.up.arrow.down")
							 }
						}
				 }
				 .task {
						do {
							 try await netWorking.fetchData()
						} catch {
							 print("Error Fetching from UI: \(error)")
						}
				 }
				 .alert("Open YouTube", isPresented: $showAlert) {
						Button("Cancel", role: .cancel) {
							 selectedURL = nil
						}
						Button("Open") {
							 if let url = selectedURL {
									UIApplication.shared.open(url)
							 }
						}
				 } message: {
						Text("This will take you to YouTube to view the recipe video.")
				 }
			}
	 }

	 private var groupedRecipes: [String: [Recipe]] {
			let filtered = filteredRecipes
			return Dictionary(grouping: filtered, by: { $0.cuisine })
	 }

	 private var filteredRecipes: [Recipe] {
			var recipes = netWorking.recipes

			if !searchText.isEmpty {
				 recipes = recipes.filter { recipe in
						recipe.name.lowercased().contains(searchText.lowercased()) ||
						recipe.cuisine.lowercased().contains(searchText.lowercased())
				 }
			}

			switch sortOrder {
				 case .nameAscending:
						recipes.sort { $0.name.lowercased() < $1.name.lowercased() }
				 case .nameDescending:
						recipes.sort { $0.name.lowercased() > $1.name.lowercased() }
			}

			return recipes
	 }

	 enum SortOrder: String, CaseIterable, Identifiable {
			case nameAscending = "Name (A-Z)"
			case nameDescending = "Name (Z-A)"
			var id: String { rawValue }
	 }
}


