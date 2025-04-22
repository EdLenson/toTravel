import SwiftUI
import SwiftData

// MARK: - SearchCountriesView
struct SearchCountriesView: View {
    let countryAccessData: [String: [CountryAccess]]
    let selectedPassport: Passport?
    let countriesManager: CountriesManager
    
    @Query private var visas: [Visa]
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool
    
    // MARK: - Computed Properties
    private var filteredCountries: [MyCountriesView.VisaCategory: [CountryAccess]] {
        guard let passport = selectedPassport else { return [:] }
        let issuingCountry = passport.issuingCountry.uppercased()
        let allCountries = countryAccessData[issuingCountry] ?? []
        
        let filtered = allCountries.filter {
            debouncedSearchText.isEmpty ||
            countriesManager.getName(forCode: $0.destination)
                .lowercased()
                .hasPrefix(debouncedSearchText.lowercased())
        }
        
        return [
            .visaFree: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa free" ||
                (Int($0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && $0.requirement != "-1")
            }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) },
            .visaOnArrival: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa on arrival"
            }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) },
            .eVisa: filtered.filter {
                let req = $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)
                return req == "e-visa" || req == "eta"
            }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) },
            .visaRequired: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa required"
            }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) },
            .noAdmission: filtered.filter {
                $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "no admission"
            }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) }
        ]
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                backgroundView
                contentView
                headerView
            }
            .background(Theme.Colors.background(for: colorScheme))
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }
            }
            .onChange(of: searchText) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    debouncedSearchText = newValue
                }
            }
        }
    }
    
    // MARK: - Views
    private var backgroundView: some View {
        Theme.Colors.background(for: colorScheme)
            .ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Tiles.listSpacing) {
                Color.clear.frame(height: 64)
                if debouncedSearchText.isEmpty {
                    placeholderView
                } else {
                    countriesListView
                }
            }
            .padding(.horizontal, Theme.Tiles.spacing)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
    }
    
    private var placeholderView: some View {
        Text(NSLocalizedString("Введите название страны для поиска", comment: "Search placeholder text"))
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Theme.Colors.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
    
    private var countriesListView: some View {
        ForEach(MyCountriesView.VisaCategory.allCases, id: \.self) { category in
            if let countries = filteredCountries[category], !countries.isEmpty {
                categoryHeader(for: category)
                ForEach(countries, id: \.destination) { country in
                    CountryRow(
                        country: country,
                        countriesManager: countriesManager,
                        showDays: category == .visaFree,
                        visa: countriesManager.getValidVisa(forCountryCode: country.destination, passport: selectedPassport, visas: visas),
                        selectedPassport: selectedPassport
                    )
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack {
            HStack(spacing: 8) {
                Button(action: { dismiss() }) {
                    Image("ic_arrowBack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                }
                searchFieldView
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(Theme.Colors.background(for: colorScheme))
            Spacer()
        }
    }
    
    private var searchFieldView: some View {
        HStack(alignment: .center, spacing: 8) {
            Image("ic_search")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Theme.Colors.text(for: colorScheme))
            TextField(NSLocalizedString("Поиск стран", comment: "Search field placeholder"), text: $searchText)
                .foregroundColor(Theme.Colors.text(for: colorScheme))
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.alternateBackground(for: colorScheme))
        .clipShape(Capsule())
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Functions
    private func categoryHeader(for category: MyCountriesView.VisaCategory) -> some View {
        Text(NSLocalizedString(category.rawValue, comment: "Visa category title"))
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Theme.Colors.text(for: colorScheme))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.background(for: colorScheme))
    }
}

// MARK: - Preview
#Preview {
    SearchCountriesView(
        countryAccessData: [:],
        selectedPassport: nil,
        countriesManager: CountriesManager.shared
    )
}
