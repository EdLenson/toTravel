import SwiftUI
import SwiftData

struct MyCountriesView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var passports: [Passport]
    @State private var selectedPassport: Passport?
    @State private var countryAccessData: [String: [CountryAccess]] = [:]
    @State private var selectedTab: VisaCategory = .visaFree
    @State private var isPassportFieldActive: Bool = false
    @State private var isShowingPassportList: Bool = false
    @State private var isShowingSearch: Bool = false
    @State private var isLoading: Bool = false // Состояние загрузки
    @ObservedObject private var countriesManager = CountriesManager.shared
    @State private var tabsScrollProxy: ScrollViewProxy?
    @State private var listScrollProxy: ScrollViewProxy?
    @State private var headerFrames: [String: CGRect] = [:]
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    
    // MARK: - Enums
    enum VisaCategory: String, CaseIterable {
        case visaFree = "Без визы"
        case visaOnArrival = "Виза по прибытии"
        case eVisa = "Электронная виза"
        case visaRequired = "Требуется виза"
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            mainContent
            headerView
                .background(Theme.Colors.background(for: colorScheme))
        }
        .background(Theme.Colors.background(for: colorScheme))
        .fullScreenCover(isPresented: $isShowingSearch) {
            SearchCountriesView(
                countryAccessData: countryAccessData,
                selectedPassport: selectedPassport,
                countriesManager: countriesManager
            )
        }
        .onAppear {
            initializeData()
        }
        .onChange(of: passports) { newPassports in
            updateSelectedPassport(with: newPassports)
        }
    }
    
    // MARK: - Computed Properties
    private func countriesForCategory(_ category: VisaCategory) -> [CountryAccess] {
        switch category {
        case .visaFree: return visaFreeCountries()
        case .visaOnArrival: return visaOnArrivalCountries()
        case .eVisa: return eVisaCountries()
        case .visaRequired: return visaRequiredCountries()
        }
    }
    
    private func visaFreeCountries() -> [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa free" ||
            (Int($0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && $0.requirement != "-1")
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) } ?? []
    }
    
    private func visaOnArrivalCountries() -> [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa on arrival"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) } ?? []
    }
    
    private func eVisaCountries() -> [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "e-visa"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) } ?? []
    }
    
    private func visaRequiredCountries() -> [CountryAccess] {
        guard let passport = selectedPassport else { return [] }
        let issuingCountry = passport.issuingCountry.uppercased()
        return countryAccessData[issuingCountry]?.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa required"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) } ?? []
    }
    
    private func getCount(for category: VisaCategory) -> Int {
        countriesForCategory(category).count
    }
    
    // MARK: - UI Components
    private var mainContent: some View {
        ScrollViewReader { listProxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Tiles.listSpacing) {
                    if passports.isEmpty {
                        Text(NSLocalizedString("Добавьте паспорт в 'Мои паспорта'", comment: ""))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Tiles.spacing)
                            .padding(.bottom, 16)
                    } else if selectedPassport == nil {
                        Text(NSLocalizedString("Выберите паспорт, чтобы увидеть доступные страны", comment: ""))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Tiles.spacing)
                            .padding(.bottom, 16)
                    } else {
                        Spacer(minLength: 100)
                        passportFieldView
                        countriesList
                    }
                }
                .padding(.horizontal, Theme.Tiles.verticalPadding)
                .padding(.bottom, 140)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                lastScrollOffset = scrollOffset
                scrollOffset = offset
                updateVisibleCategory()
            }
            .onPreferenceChange(HeaderFramePreferenceKey.self) { frames in
                headerFrames = frames
                updateVisibleCategory()
            }
            .onAppear {
                listScrollProxy = listProxy
            }
        }
    }
    
    private var passportFieldView: some View {
        UnderlinedSelectionField(
            title: NSLocalizedString("Паспорт", comment: ""),
            selectedValue: Binding(get: { selectedPassport?.customName }, set: { _ in }),
            isActive: isPassportFieldActive,
            action: { isPassportFieldActive = true; isShowingPassportList = true },
            onSelection: {}
        )
        .actionSheet(isPresented: $isShowingPassportList) {
            ActionSheet(
                title: Text(NSLocalizedString("Выберите паспорт", comment: "")),
                buttons: passports.map { passport in
                    .default(Text(passport.customName.isEmpty ? NSLocalizedString("Без названия", comment: "") : passport.customName)) {
                        selectedPassport = passport
                        isPassportFieldActive = false
                        isShowingPassportList = false
                    }
                } + [.cancel { isPassportFieldActive = false; isShowingPassportList = false }]
            )
        }
        .padding(.top, 16)
    }
    
    private var countriesList: some View {
        ForEach(VisaCategory.allCases, id: \.self) { category in
            Section(header: categoryHeader(for: category)) {
                if isLoading {
                    ForEach(0..<5) { _ in // Плейсхолдер для 5 элементов
                        placeholderCountryRow
                    }
                } else {
                    ForEach(countriesForCategory(category), id: \.destination) { country in
                        CountryRow(
                            country: country,
                            countriesManager: countriesManager,
                            showDays: category == .visaFree
                        )
                    }
                }
            }
            .id(category.rawValue)
        }
    }
    
    private var placeholderCountryRow: some View {
        Rectangle()
            .fill(Theme.Colors.alternateBackground(for: colorScheme))
            .frame(height: 60)
            .cornerRadius(12)
            .opacity(0.5)
            .transition(.opacity)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isLoading)
    }
    
    private var headerView: some View {
        VStack(spacing: 24) {
            headerTitle
            tabsView
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
    
    private var headerTitle: some View {
        HStack {
            Text(NSLocalizedString("Страны", comment: ""))
                .font(Theme.Fonts.header)
                .foregroundColor(Theme.Colors.text(for: colorScheme))
            Spacer()
            Button(action: { isShowingSearch = true }) {
                Image("ic_search")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var tabsView: some View {
        ScrollViewReader { tabsProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Tiles.tabSpacing) {
                    ForEach(VisaCategory.allCases, id: \.self) { category in
                        Button(action: { selectTab(category) }) {
                            Text("\(NSLocalizedString(category.rawValue, comment: "")) \(getCount(for: category))")
                                .font(Theme.Fonts.tab)
                                .foregroundColor(selectedTab == category ? Theme.Colors.background(for: colorScheme) : Theme.Colors.secondary)
                                .padding(.horizontal, Theme.Tiles.tabHorizontalPadding)
                                .padding(.vertical, Theme.Tiles.tabVerticalPadding)
                                .background(selectedTab == category ? Theme.Colors.primary : Theme.Colors.surface(for: colorScheme))
                                .cornerRadius(Theme.Tiles.tabCornerRadius)
                        }
                        .id(category.rawValue)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
            }
            .onAppear { tabsProxy.scrollTo(selectedTab.rawValue, anchor: .center); tabsScrollProxy = tabsProxy }
        }
    }
    
    private func categoryHeader(for category: VisaCategory) -> some View {
        Text(NSLocalizedString(category.rawValue, comment: ""))
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Theme.Colors.text(for: colorScheme))
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: HeaderFramePreferenceKey.self, value: [category.rawValue: geometry.frame(in: .named("scroll"))])
                }
            )
    }
    
    // MARK: - Helper Functions
    private func initializeData() {
        isLoading = true
        countryAccessData = countriesManager.getCountryAccessData()
        if !passports.isEmpty && selectedPassport == nil {
            selectedPassport = passports.first
        }
        Task {
            await updateDataInBackground()
            await MainActor.run { isLoading = false }
        }
    }
    
    private func updateDataInBackground() async {
        do {
            let newData = try await CSVParser.fetchCountryAccessData()
            await MainActor.run { self.countryAccessData = newData }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
    
    private func updateSelectedPassport(with newPassports: [Passport]) {
        if newPassports.isEmpty {
            selectedPassport = nil
        } else if !newPassports.contains(where: { $0 === selectedPassport }) {
            selectedPassport = newPassports.first
        }
    }
    
    private func updateVisibleCategory() {
        let isScrollingUp = scrollOffset > lastScrollOffset
        let threshold: CGFloat = 300
        
        if let currentFrame = headerFrames[selectedTab.rawValue] {
            let currentRelativeY = currentFrame.minY - scrollOffset
            if !isScrollingUp && currentRelativeY > threshold {
                if let currentIndex = VisaCategory.allCases.firstIndex(of: selectedTab),
                   currentIndex > 0 {
                    let previousCategory = VisaCategory.allCases[currentIndex - 1]
                    selectedTab = previousCategory
                    centerTabIfNotFullyVisible(previousCategory)
                    return
                }
            }
        }
        
        let visibleCategory = VisaCategory.allCases.first { category in
            guard let frame = headerFrames[category.rawValue] else { return false }
            let relativeY = frame.minY - scrollOffset
            return relativeY < threshold && relativeY + frame.height > 0
        }
        
        if let visibleCategory = visibleCategory, selectedTab != visibleCategory {
            selectedTab = visibleCategory
            centerTabIfNotFullyVisible(visibleCategory)
        }
    }
    
    private func centerTabIfNotFullyVisible(_ category: VisaCategory) {
        withAnimation(.easeInOut(duration: 0.3)) {
            tabsScrollProxy?.scrollTo(category.rawValue, anchor: .center)
        }
    }
    
    private func selectTab(_ category: VisaCategory) {
        selectedTab = category
        listScrollProxy?.scrollTo(category.rawValue, anchor: UnitPoint(x: 0, y: 0.15))
        centerTabIfNotFullyVisible(category)
    }
}

// MARK: - Preference Keys
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HeaderFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

#Preview {
    MyCountriesView()
}
