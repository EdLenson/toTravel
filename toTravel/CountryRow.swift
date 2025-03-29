import SwiftUI
import SwiftData

// CountryRow.swift
struct CountryRow: View {
    let country: CountryAccess
    let countriesManager: CountriesManager
    let showDays: Bool
    @State private var flagImage: UIImage? = nil
    @State private var flagLoadError: Bool = false
    
    private func flagURL(for countryCode: String) -> URL? {
        let code = countryCode.lowercased()
        let urlString = "https://flagcdn.com/w320/\(code).png"
        return URL(string: urlString)
    }
    
    private func loadFlagImage() {
        guard let url = flagURL(for: country.destination) else {
            flagLoadError = true
            return
        }
        
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(country.destination.lowercased()).png")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                DispatchQueue.main.async {
                    self.flagImage = image
                }
                return
            }
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.flagLoadError = true
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.flagLoadError = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.flagImage = image
                try? data.write(to: fileURL)
            }
        }.resume()
    }
    
    private var daysText: String {
        let requirement = country.requirement.trimmingCharacters(in: .whitespacesAndNewlines)
        if let days = Int(requirement), days > 0 {
            return "до \(days) дн."
        } else {
            return "до 365 дней*"
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if flagImage == nil && !flagLoadError {
                Color.gray
                    .frame(width: 48, height: 48)
            } else if flagLoadError {
                Color.gray
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    )
            } else if let image = flagImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(countriesManager.getName(forCode: country.destination))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1C"))
                
                if showDays {
                    Text(daysText)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#9393A8"))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .cornerRadius(64)
        .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.18).opacity(0.02), radius: 9, x: 0, y: 5)
        .onAppear {
            loadFlagImage()
        }
        .onChange(of: country.destination) { _ in
            flagImage = nil
            flagLoadError = false
            loadFlagImage()
        }
    }
}

