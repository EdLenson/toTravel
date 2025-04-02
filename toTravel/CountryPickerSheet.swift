import SwiftUI

struct CountryList: View {
    @Binding var selectedCountry: String // Это будет название страны, возвращаемое пользователю
    @Binding var isShowing: Bool
    @StateObject private var countriesManager = CountriesManager.shared
    @State private var searchText = ""
    @State private var flagImages: [String: UIImage] = [:] // Ключ — код страны (cca2)
    
    var filteredCountries: [String] {
        if searchText.isEmpty {
            return countriesManager.countryNames
        } else {
            return countriesManager.countryNames.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func loadFlagImage(forCode code: String) {
        let lowerCode = code.lowercased()
        guard let url = countriesManager.getFlagURL(forCode: code) else {
            print("Ошибка: URL флага недоступен для кода \(code)")
            return
        }
        
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(lowerCode).png")
        
        if let cachedImage = flagImages[lowerCode] {
            print("Флаг для кода \(code) найден в памяти")
            return
        }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                DispatchQueue.main.async {
                    self.flagImages[lowerCode] = image
                    print("Флаг загружен с диска для кода \(code)")
                }
                return
            } else {
                print("Файл существует, но не удалось загрузить изображение: \(fileURL.path)")
            }
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка сети для \(url): \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Неверный ответ сервера для \(url): \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Не удалось декодировать данные для \(url)")
                return
            }
            
            DispatchQueue.main.async {
                self.flagImages[lowerCode] = image
                print("Флаг загружен из сети для кода \(code)")
                do {
                    try data.write(to: fileURL)
                    print("Флаг сохранён на диск: \(fileURL.path)")
                } catch {
                    print("Ошибка сохранения на диск: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(filteredCountries, id: \.self) { country in
                    Button(action: {
                        selectedCountry = country // Возвращаем название страны
                        isShowing = false
                    }) {
                        HStack(spacing: 8) {
                            if let code = countriesManager.getCode(for: country),
                               let image = flagImages[code.lowercased()] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 15)
                            } else {
                                Color.gray
                                    .frame(width: 20, height: 15)
                                    .onAppear {
                                        if let code = countriesManager.getCode(for: country) {
                                            loadFlagImage(forCode: code)
                                        }
                                    }
                            }
                            Text(country)
                                .foregroundColor(.black)
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.top, 16)
            }
            .navigationTitle("Выберите страну")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    isShowing = false
                }) {
                    Text("Отменить")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    CountryList(selectedCountry: .constant("Россия"), isShowing: .constant(true))
}
