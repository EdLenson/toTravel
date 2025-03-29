import SwiftUI
import SwiftData

struct MyCountriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var passports: [Passport]
    @State private var selectedPassport: Passport?
    @State private var countryAccessData: [String: [CountryAccess]] = [:]
    @State private var selectedTab: VisaCategory = .visaFree
    @State private var isPassportFieldActive: Bool = false
    @State private var isShowingPassportList: Bool = false
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    enum VisaCategory: String, CaseIterable {
        case visaFree = "Без визы"
        case visaOnArrival = "Виза по прибытии"
        case eVisa = "Электронная виза"
        case visaRequired = "Требуется виза"
    }
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private var visaFreeCountries: [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa free" ||
            (Int($0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && $0.requirement != "-1")
        } ?? []
    }
    
    private var visaOnArrivalCountries: [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa on arrival"
        } ?? []
    }
    
    private var visaRequiredCountries: [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa required"
        } ?? []
    }
    
    private var eVisaCountries: [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "e-visa"
        } ?? []
    }
    
    private var currentCountries: [CountryAccess] {
        switch selectedTab {
        case .visaFree: return visaFreeCountries
        case .visaOnArrival: return visaOnArrivalCountries
        case .eVisa: return eVisaCountries
        case .visaRequired: return visaRequiredCountries
        }
    }
    
    private func getCount(for category: VisaCategory) -> Int {
        switch category {
        case .visaFree: return visaFreeCountries.count
        case .visaOnArrival: return visaOnArrivalCountries.count
        case .eVisa: return eVisaCountries.count
        case .visaRequired: return visaRequiredCountries.count
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Фиксированная верхняя часть с полем выбора и табами
                VStack(spacing: 0) {
                    UnderlinedSelectionField(
                        title: "Паспорт",
                        selectedValue: Binding(
                            get: { selectedPassport?.customName ?? "" },
                            set: { _ in }
                        ),
                        isActive: isPassportFieldActive,
                        action: {
                            isPassportFieldActive = true
                            isShowingPassportList = true
                        },
                        onSelection: {}
                    )
                    .actionSheet(isPresented: $isShowingPassportList) {
                        ActionSheet(
                            title: Text("Выберите паспорт"),
                            buttons: passports.map { passport in
                                .default(Text(passport.customName.isEmpty ? "Без названия" : passport.customName)) {
                                    selectedPassport = passport
                                    isPassportFieldActive = false
                                    isShowingPassportList = false
                                }
                            } + [.cancel {
                                isPassportFieldActive = false
                                isShowingPassportList = false
                            }]
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .background(Color(.systemBackground))
                    
                    if selectedPassport != nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(VisaCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedTab = category
                                    }) {
                                        HStack(alignment: .center, spacing: 10) {
                                            Text("\(category.rawValue) \(getCount(for: category))")
                                                .font(.system(size: 14)) // Увеличен шрифт до 14pt
                                                .foregroundColor(selectedTab == category ? .white : .primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedTab == category ?
                                            Color(red: 0.39, green: 0.39, blue: 0.8) :
                                            .white
                                        )
                                        .cornerRadius(100)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(Color(.systemBackground))
                    }
                }
                
                // Список стран с прокруткой
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if passports.isEmpty {
                            Text("Добавьте паспорт в 'Мои паспорта'")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if selectedPassport == nil {
                            Text("Выберите паспорт, чтобы увидеть доступные страны")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ForEach(currentCountries, id: \.destination) { country in
                                CountryRow(
                                    country: country,
                                    countriesManager: countriesManager,
                                    showDays: selectedTab == .visaFree
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16) // Уменьшен отступ сверху до 16 пикселей
                    .padding(.bottom, 16)
                }
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.97))
            .navigationTitle("Мои страны")
            .navigationBarTitleDisplayMode(.automatic)
            .onAppear {
                countryAccessData = countriesManager.getCountryAccessData()
                if !passports.isEmpty && selectedPassport == nil {
                    selectedPassport = passports.first
                }
                Task {
                    await updateDataInBackground()
                }
            }
        }
    }
    
    private func updateDataInBackground() async {
        do {
            let newData = try await CSVParser.fetchCountryAccessData()
            await MainActor.run {
                self.countryAccessData = newData
            }
        } catch {
            print("Ошибка фонового обновления данных: \(error.localizedDescription)")
        }
    }
}

#Preview {
    MyCountriesView()
}
