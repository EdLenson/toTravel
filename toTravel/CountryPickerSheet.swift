//
//  CountryPickerView.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI

struct CountryList: View {
    @Binding var selectedCountry: String
    @Binding var isShowing: Bool
    @StateObject private var countriesManager = CountriesManager.shared
    @State private var searchText = ""
    @State private var flagImages: [String: UIImage] = [:]
    
    var filteredCountries: [String] {
        if searchText.isEmpty {
            return countriesManager.countries
        } else {
            return countriesManager.countries.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func flagURL(for country: String) -> URL? {
        if let code = countriesManager.getCode(for: country)?.lowercased() {
            let urlString = "https://flagcdn.com/w320/\(code).png"
            print("Формирую URL для \(country): \(urlString)")
            return URL(string: urlString)
        }
        print("Код не найден для страны \(country)")
        return nil
    }
    
    private func loadFlagImage(for country: String) {
        guard let code = countriesManager.getCode(for: country),
              let url = flagURL(for: country) else {
            print("Ошибка: код страны или URL недоступны для \(country)")
            return
        }
        
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(code).png")
        
        if let cachedImage = flagImages[country] {
            print("Флаг для \(country) найден в памяти")
            return
        }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                DispatchQueue.main.async {
                    self.flagImages[country] = image
                    print("Флаг загружен с диска для \(country)")
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
                self.flagImages[country] = image
                print("Флаг загружен из сети для \(country)")
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
                        selectedCountry = country
                        isShowing = false
                    }) {
                        HStack(spacing: 8) {
                            if let image = flagImages[country] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 15)
                            } else {
                                Color.gray
                                    .frame(width: 20, height: 15)
                                    .onAppear {
                                        loadFlagImage(for: country)
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
