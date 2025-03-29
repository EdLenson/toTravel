import SwiftUI

struct VisaTileView: View {
    let visa: Visa
    let dateFormatter: DateFormatter
    
    @StateObject private var countriesManager = CountriesManager.shared
    @State private var flagImage: UIImage? = nil
    
    private var isExpiringSoon: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: visa.endDate)
        let components = Calendar.current.dateComponents([.month], from: today, to: end)
        let monthsLeft = components.month ?? 0
        return monthsLeft < 3 && end > today
    }
    
    private func flagURL(for country: String) -> URL? {
        if let code = countriesManager.getCode(for: country)?.lowercased() {
            let urlString = "https://flagcdn.com/w320/\(code).png"
            print("Формирую URL для \(country): \(urlString)")
            return URL(string: urlString)
        } else {
            print("Код не найден для страны \(country)")
            return nil
        }
    }
    
    private func loadFlagImage() {
        guard let code = countriesManager.getCode(for: visa.issuingCountry),
              let url = flagURL(for: visa.issuingCountry) else {
            print("Ошибка: код страны или URL недоступны для \(visa.issuingCountry)")
            return
        }
        
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(code).png")
        
        // Проверяем, есть ли флаг в кэше
        if fileManager.fileExists(atPath: fileURL.path) {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                DispatchQueue.main.async {
                    self.flagImage = image
                    print("Флаг загружен с диска для \(visa.issuingCountry)")
                }
                return
            } else {
                print("Файл существует, но не удалось загрузить изображение: \(fileURL.path)")
            }
        }
        
        // Если флага нет в кэше, загружаем из сети
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
                self.flagImage = image
                print("Флаг загружен из сети для \(visa.issuingCountry)")
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
        HStack(alignment: .center, spacing: 8) {
            // Отображаем флаг или заглушку без индикации загрузки
            if let image = flagImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
            } else {
                Color.gray
                    .frame(width: 40, height: 30)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(visa.customName.isEmpty ? "Без названия" : visa.customName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("до \(dateFormatter.string(from: visa.endDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 0)
        .frame(width: 361, height: 80, alignment: .leading)
        .background(.white)
        .cornerRadius(8)
        .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.18).opacity(0.07), radius: 7.5, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(
                    isExpiringSoon ? Color(red: 1, green: 0.4, blue: 0.38) : Color(red: 0.94, green: 0.94, blue: 0.94),
                    lineWidth: 1
                )
        )
        .onAppear {
            loadFlagImage()
        }
        .onChange(of: visa.issuingCountry) { _ in
            flagImage = nil
            loadFlagImage()
        }
    }
}
