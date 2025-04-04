import SwiftUI
import SwiftData

struct MyDocumentsView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var passports: [Passport]
    @Query private var visas: [Visa]
    @State private var isShowingAddSheet: Bool = false
    @State private var isShowingAddPassportView: Bool = false
    @State private var isShowingAddVisaView: Bool = false
    @Binding var selectedPassportForDetail: Passport?
    @Binding var selectedVisaForDetail: Visa?
    
    // MARK: - Date Formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    // MARK: - Computed Properties
    
    /// Сортирует паспорта по дате истечения срока, приоритет у просроченных или скоро истекающих
    private var sortedPassports: [Passport] {
        passports.sorted { passport1, passport2 in
            let today = Calendar.current.startOfDay(for: Date())
            let expiry1 = Calendar.current.startOfDay(for: passport1.expiryDate)
            let expiry2 = Calendar.current.startOfDay(for: passport2.expiryDate)
            
            let monthsLeft1 = Calendar.current.dateComponents([.month], from: today, to: expiry1).month ?? 0
            let monthsLeft2 = Calendar.current.dateComponents([.month], from: today, to: expiry2).month ?? 0
            
            let isExpiringSoon1 = monthsLeft1 < 6 || expiry1 < today
            let isExpiringSoon2 = monthsLeft2 < 6 || expiry2 < today
            
            if isExpiringSoon1 != isExpiringSoon2 {
                return isExpiringSoon1 && !isExpiringSoon2
            }
            return expiry1 < expiry2
        }
    }
    
    /// Фильтрует визы, оставляя только те, что привязаны к паспорту
    private var validVisas: [Visa] {
        visas.filter { $0.passport != nil }
    }
    
    /// Сортирует визы по дате окончания, приоритет у просроченных или скоро истекающих
    private var sortedVisas: [Visa] {
        validVisas.sorted { visa1, visa2 in
            let today = Calendar.current.startOfDay(for: Date())
            let end1 = Calendar.current.startOfDay(for: visa1.endDate)
            let end2 = Calendar.current.startOfDay(for: visa2.endDate)
            
            let monthsLeft1 = Calendar.current.dateComponents([.month], from: today, to: end1).month ?? 0
            let monthsLeft2 = Calendar.current.dateComponents([.month], from: today, to: end2).month ?? 0
            
            let isExpiringSoon1 = monthsLeft1 < 3 || end1 <= today
            let isExpiringSoon2 = monthsLeft2 < 3 || end2 <= today
            
            if isExpiringSoon1 != isExpiringSoon2 {
                return isExpiringSoon1 && !isExpiringSoon2
            }
            return end1 < end2
        }
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Passports Section
                passportsSection
                
                // MARK: - Visas Section
                visasSection
                
                // MARK: - Add Button
                Button(action: {
                    isShowingAddSheet = true
                }) {
                    Text(NSLocalizedString("Добавить", comment: ""))
                        .font(Theme.Fonts.button)
                        .foregroundColor(Theme.Colors.textInverse)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.primary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Tiles.cornerRadius))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 32)
                .padding(.horizontal, Theme.Tiles.spacing)
            }
            .background(Theme.Colors.background(for: colorScheme))
        }
        .background(Theme.Colors.background(for: colorScheme))
        .actionSheet(isPresented: $isShowingAddSheet) {
            ActionSheet(
                title: Text(NSLocalizedString("Добавить документ", comment: "")),
                buttons: [
                    .default(Text(NSLocalizedString("Паспорт", comment: ""))) {
                        isShowingAddPassportView = true
                    },
                    .default(Text(NSLocalizedString("Виза", comment: ""))) {
                        isShowingAddVisaView = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $isShowingAddPassportView) {
            AddPassportView(isShowingAddPassportView: $isShowingAddPassportView)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingAddVisaView) {
            AddVisaView(isShowingAddVisaView: $isShowingAddVisaView)
                .presentationDetents([.large])
        }
    }
    
    // MARK: - UI Components
    
    /// Секция отображения списка паспортов
    private var passportsSection: some View {
        Group {
            HStack {
                Text(NSLocalizedString("Мои паспорта", comment: ""))
                    .font(Theme.Fonts.header)
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                Spacer()
            }
            .padding(.horizontal, Theme.Tiles.spacing)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(Theme.Colors.background(for: colorScheme))
            .frame(maxWidth: .infinity)
            
            if passports.isEmpty {
                Text(NSLocalizedString("Добавьте паспорт", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Tiles.spacing)
                    .padding(.bottom, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Tiles.listSpacing) {
                        ForEach(sortedPassports) { passport in
                            Button(action: {
                                togglePassportSelection(passport)
                            }) {
                                PassportTileView(passport: passport, dateFormatter: dateFormatter)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Tiles.spacing)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    /// Секция отображения списка виз
    private var visasSection: some View {
        Group {
            HStack {
                Text(NSLocalizedString("Мои визы", comment: ""))
                    .font(Theme.Fonts.header)
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                Spacer()
            }
            .padding(.horizontal, Theme.Tiles.spacing)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .background(Theme.Colors.background(for: colorScheme))
            .frame(maxWidth: .infinity)
            
            if validVisas.isEmpty {
                Text(NSLocalizedString("Добавьте визу в паспорт", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Tiles.spacing)
                    .padding(.bottom, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Tiles.listSpacing) {
                        ForEach(sortedVisas) { visa in
                            Button(action: {
                                toggleVisaSelection(visa)
                            }) {
                                VisaTileView(visa: visa, dateFormatter: dateFormatter)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Tiles.spacing)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Переключает выбор паспорта для детального просмотра
    private func togglePassportSelection(_ passport: Passport) {
        if selectedPassportForDetail == passport {
            selectedPassportForDetail = nil
        }
        DispatchQueue.main.async {
            selectedPassportForDetail = passport
        }
    }
    
    /// Переключает выбор визы для детального просмотра
    private func toggleVisaSelection(_ visa: Visa) {
        if selectedVisaForDetail == visa {
            selectedVisaForDetail = nil
        }
        DispatchQueue.main.async {
            selectedVisaForDetail = visa
        }
    }
}

#Preview {
    MyDocumentsView(
        selectedPassportForDetail: .constant(nil),
        selectedVisaForDetail: .constant(nil)
    )
}
