import SwiftUI

struct SearchCountriesView: View {
    let countryAccessData: [String: [CountryAccess]]
    let selectedPassport: Passport?
    let countriesManager: CountriesManager
    
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool
    
    private var filteredCountries: [MyCountriesView.VisaCategory: [CountryAccess]] {
        guard let passport = selectedPassport else { return [:] }
        let issuingCountry = passport.issuingCountry.uppercased()
        let allCountries = countryAccessData[issuingCountry] ?? []
        
        let filtered = allCountries.filter {
            searchText.isEmpty || countriesManager.getName(forCode: $0.destination).lowercased().contains(searchText.lowercased())
        }
        
        return [
            .visaFree: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa free" ||
                (Int($0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && $0.requirement != "-1")
            },
            .visaOnArrival: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa on arrival"
            },
            .eVisa: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "e-visa"
            },
            .visaRequired: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa required"
            }
        ]
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) { // Отступ 8 между стрелкой и полем
                    Button(action: { dismiss() }) {
                        Image("ic_arrowBack")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                    }
                    
                    HStack(alignment: .center, spacing: 8) {
                        Image("ic_search")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                        
                        TextField("Поиск стран", text: $searchText)
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                            .focused($isSearchFieldFocused)
                            .submitLabel(.search)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.alternateBackground(for: colorScheme))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16) // Симметричные отступы 16 по бокам
                .background(Theme.Colors.background(for: colorScheme))
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Theme.Tiles.listSpacing) {
                        if searchText.isEmpty {
// тут может быть текст, когда поиск пустой
                        } else {
                            ForEach(MyCountriesView.VisaCategory.allCases, id: \.self) { category in
                                if let countries = filteredCountries[category], !countries.isEmpty {
                                    Text(category.rawValue)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                    
                                    ForEach(countries, id: \.destination) { country in
                                        CountryRow(
                                            country: country,
                                            countriesManager: countriesManager,
                                            showDays: category == .visaFree
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Tiles.spacing)
                    .padding(.bottom, 16)
                }
            }
            .background(Theme.Colors.background(for: colorScheme))
            .navigationBarHidden(true)
            .onAppear {
                isSearchFieldFocused = true
            }
        }
    }
}

#Preview {
    SearchCountriesView(
        countryAccessData: [:],
        selectedPassport: nil,
        countriesManager: CountriesManager.shared
    )
}
