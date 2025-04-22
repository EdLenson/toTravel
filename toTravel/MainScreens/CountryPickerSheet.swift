import SwiftUI

// MARK: - CountryList
struct CountryList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedCountry: String
    @Binding var isShowing: Bool
    @StateObject private var countriesManager = CountriesManager.shared
    @State private var searchText = ""
    @State private var flagImages: [String: UIImage] = [:]
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // MARK: - Computed Properties
    var filteredCountries: [String] {
        let allCountries = countriesManager.countryNames
        print("CountryList: все страны = \(allCountries.count), searchText = '\(searchText)'")
        if searchText.isEmpty {
            return allCountries
        } else {
            let filtered = allCountries.filter { $0.lowercased().contains(searchText.lowercased()) }
            print("CountryList: отфильтровано = \(filtered.count)")
            return filtered
        }
    }
    
    // MARK: - Helper Functions
    private func loadFlags() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        
        for country in filteredCountries {
            guard let code = countriesManager.getCode(for: country)?.lowercased(),
                  flagImages[code] == nil,
                  let url = countriesManager.getFlagURL(forCode: code) else { continue }
            
            let operation = BlockOperation {
                let fileManager = FileManager.default
                let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let fileURL = cachesDirectory.appendingPathComponent("\(code).png")
                
                if fileManager.fileExists(atPath: fileURL.path),
                   let image = UIImage(contentsOfFile: fileURL.path) {
                    DispatchQueue.main.async {
                        self.flagImages[code] = image
                        print("Флаг загружен с диска для кода \(code)")
                    }
                    return
                }
                
                guard let (data, response) = try? URLSession.shared.synchronousDataTask(with: url),
                      let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let image = UIImage(data: data) else {
                    print("Ошибка загрузки флага для \(code)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.flagImages[code] = image
                    try? data.write(to: fileURL)
                    print("Флаг сохранён на диск: \(fileURL.path)")
                }
            }
            queue.addOperation(operation)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.secondary))
                        .frame(maxWidth: .infinity)
                } else if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if countriesManager.countries.isEmpty {
                    Text(NSLocalizedString("Загрузка стран...", comment: "Loading countries"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.secondary)
                        .padding()
                } else {
                    List(filteredCountries, id: \.self) { country in
                        Button(action: {
                            selectedCountry = country
                            isShowing = false
                        }) {
                            HStack(spacing: 8) {
                                if let code = countriesManager.getCode(for: country)?.lowercased() {
                                    if let image = flagImages[code] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 15)
                                    } else {
                                        LoadingFlagPlaceholder(width: 20, height: 15)
                                            .onAppear { loadFlags() }
                                    }
                                }
                                Text(country)
                                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.background(for: colorScheme))
                    .padding(.top, 16)
                }
            }
            .navigationTitle(NSLocalizedString("Выберите страну", comment: "Choose a country"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    isShowing = false
                }) {
                    Text(NSLocalizedString("Отменить", comment: "Cancel button"))
                        .font(.headline)
                        .foregroundColor(Theme.Colors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.surface(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Theme.Colors.background(for: colorScheme))
            .onAppear {
                print("CountryList отображается, countries.count = \(countriesManager.countries.count)")
                if countriesManager.countries.isEmpty {
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Даем время на загрузку
                        if countriesManager.countries.isEmpty {
                            errorMessage = NSLocalizedString("Ошибка загрузки стран", comment: "Loading error")
                        }
                        isLoading = false
                    }
                } else {
                    loadFlags()
                }
            }
            .onChange(of: searchText) { _, _ in // Обновлено для iOS 17+
                loadFlags()
            }
        }
    }
}

// MARK: - URLSession Extension
extension URLSession {
    func synchronousDataTask(with url: URL) throws -> (Data, URLResponse) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (Data, URLResponse)?
        var error: Error?
        
        let task = dataTask(with: url) { data, response, taskError in
            if let taskError = taskError {
                error = taskError
            } else if let data = data, let response = response {
                result = (data, response)
            }
            semaphore.signal()
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        if let error = error { throw error }
        guard let result = result else { fatalError("No data or response received") }
        return result
    }
}

// MARK: - Preview
#Preview {
    CountryList(selectedCountry: .constant("Россия"), isShowing: .constant(true))
}
