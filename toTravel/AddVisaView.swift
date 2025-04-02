import SwiftUI
import SwiftData

struct AddVisaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Passport> { $0.type != "Внутренний" }) private var passports: [Passport]
    @Binding var isShowingAddVisaView: Bool
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var customName = ""
    @State private var selectedPassport: Passport?
    @State private var issuingCountry: String? // Хранит код страны (cca2)
    @State private var entriesCount = ""
    @State private var isUnlimitedEntries = false
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var startDateString = ""
    @State private var endDateString = ""
    @State private var stayDuration = ""
    @State private var isUnlimitedStay = false
    @State private var isShowingCountryList = false
    @State private var isShowingPassportList = false
    @State private var currentFieldIndex = -1
    @FocusState private var focusedField: String?
    
    private var minimumDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var lastEditableFieldIndex: Int { isUnlimitedStay ? 5 : 6 }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    formContent
                        .padding(.horizontal, 16)
                }
                .navigationTitle("Добавить визу")
                .navigationBarItems(trailing: closeButton)
                .safeAreaInset(edge: .bottom) { bottomButton }
                .onTapGesture { dismissKeyboard(); currentFieldIndex = -1; focusedField = nil }
                .onChange(of: focusedField) { handleFocusChange($0, scrollProxy: scrollProxy) }
            }
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 20) {
            visaNameField
            passportField
            issuingCountryField
            entriesSection
            startDateField
            endDateField
            stayDurationSection
            saveButton
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private var visaNameField: some View {
        UnderlinedTextField(title: "Название визы", text: $customName)
            .focused($focusedField, equals: "customName")
            .submitLabel(.next)
            .onTapGesture { setFieldActive(0) }
            .onSubmit { moveToNextField() }
    }
    
    private var passportField: some View {
        UnderlinedSelectionField(
            title: "Паспорт",
            selectedValue: Binding(get: { selectedPassport?.customName }, set: { _ in }),
            isActive: currentFieldIndex == 1,
            action: { setFieldActive(1); isShowingPassportList = true },
            onSelection: {}
        )
        .actionSheet(isPresented: $isShowingPassportList) {
            ActionSheet(
                title: Text("Выберите паспорт"),
                buttons: passports.map { passport in
                    .default(Text(passport.customName)) {
                        selectedPassport = passport
                        moveToNextField()
                    }
                } + [.cancel()]
            )
        }
    }
    
    private var issuingCountryField: some View {
        UnderlinedSelectionField(
            title: "Страна выдачи",
            selectedValue: Binding(
                get: { issuingCountry != nil ? countriesManager.getName(forCode: issuingCountry!) : nil },
                set: { _ in }
            ),
            isActive: currentFieldIndex == 2,
            action: { setFieldActive(2); isShowingCountryList = true },
            onSelection: {}
        )
        .sheet(isPresented: $isShowingCountryList) {
            CountryList(selectedCountry: Binding(
                get: { issuingCountry != nil ? countriesManager.getName(forCode: issuingCountry!) : "" },
                set: { issuingCountry = countriesManager.getCode(for: $0) ?? "Unknown"; moveToNextField() }
            ), isShowing: $isShowingCountryList)
        }
    }
    
    private var entriesSection: some View {
        Group {
            if !isUnlimitedEntries {
                UnderlinedTextField(title: "Количество въездов", text: $entriesCount)
                    .focused($focusedField, equals: "entriesCount")
                    .keyboardType(.numberPad)
                    .submitLabel(.next)
                    .onTapGesture { setFieldActive(3) }
                    .onSubmit { moveToNextField() }
            }
            CustomCheckbox(isChecked: $isUnlimitedEntries, title: "Неограниченное количество")
                .onChange(of: isUnlimitedEntries) { handleEntriesToggle($0) }
        }
    }
    
    private var startDateField: some View {
        UnderlinedDateField(
            title: "Дата начала действия",
            date: $startDate,
            dateString: $startDateString
        )
        .focused($focusedField, equals: "startDate")
        .submitLabel(.next)
        .onTapGesture { setFieldActive(4) }
        .onSubmit { moveToNextField() }
    }
    
    private var endDateField: some View {
        UnderlinedDateField(
            title: "Дата окончания действия",
            date: $endDate,
            dateString: $endDateString,
            minimumDate: startDate
        )
        .focused($focusedField, equals: "endDate")
        .submitLabel(.next)
        .onTapGesture { setFieldActive(5) }
        .onSubmit { moveToNextField() }
    }
    
    private var stayDurationSection: some View {
        Group {
            if !isUnlimitedStay {
                UnderlinedTextField(title: "Продолжительность пребывания", text: $stayDuration)
                    .focused($focusedField, equals: "stayDuration")
                    .keyboardType(.numberPad)
                    .submitLabel(.done)
                    .onTapGesture { setFieldActive(6) }
                    .onSubmit { moveToNextField() }
            }
            CustomCheckbox(isChecked: $isUnlimitedStay, title: "Неограниченно")
                .onChange(of: isUnlimitedStay) { handleStayToggle($0) }
        }
    }
    
    private var saveButton: some View {
        Group {
            if allFieldsFilled && currentFieldIndex > lastEditableFieldIndex {
                Button(action: saveVisa) {
                    Text("Сохранить")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.primary)
                        .foregroundColor(Theme.Colors.textInverse)
                        .cornerRadius(Theme.Tiles.cornerRadius)
                }
                .padding(.top, 20)
                .id("saveButton")
            }
        }
    }
    
    private var closeButton: some View {
        Button("Закрыть") { isShowingAddVisaView = false }
    }
    
    private var bottomButton: some View {
        Group {
            if (focusedField != nil || (currentFieldIndex >= 0 && currentFieldIndex <= lastEditableFieldIndex)) && !isSelectionField {
                HStack {
                    Spacer()
                    Button(action: moveToNextField) {
                        Text(currentFieldIndex == lastEditableFieldIndex ? "Готово" : "Далее")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Theme.Colors.primary)
                            .foregroundColor(Theme.Colors.textInverse)
                            .cornerRadius(Theme.Tiles.cornerRadius)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    private var allFieldsFilled: Bool {
        !customName.isEmpty &&
        selectedPassport != nil &&
        issuingCountry != nil &&
        (isUnlimitedEntries || !entriesCount.isEmpty) &&
        startDate != nil && startDateString.count == 10 &&
        endDate != nil && endDateString.count == 10 &&
        (isUnlimitedStay || (!stayDuration.isEmpty && Int(stayDuration) != nil))
    }
    
    private var isSelectionField: Bool {
        currentFieldIndex == 1 || currentFieldIndex == 2
    }
    
    private func fieldIndex(for field: String) -> Int {
        switch field {
        case "customName": return 0
        case "passport": return 1
        case "issuingCountry": return 2
        case "entriesCount": return 3
        case "startDate": return 4
        case "endDate": return 5
        case "stayDuration": return 6
        default: return -1
        }
    }
    
    private func setFieldActive(_ index: Int) {
        guard index >= 0 && index <= lastEditableFieldIndex else { return }
        currentFieldIndex = index
        focusedField = ["customName", "passport", "issuingCountry", "entriesCount", "startDate", "endDate", "stayDuration"][index]
        if index == 1 || index == 2 { dismissKeyboard() }
    }
    
    private func moveToNextField() {
        if currentFieldIndex < 0 {
            setFieldActive(0)
            return
        }
        var nextIndex = currentFieldIndex + 1
        if isUnlimitedEntries && nextIndex == 3 { nextIndex += 1 }
        if isUnlimitedStay && nextIndex == 6 { nextIndex += 1 }
        
        if nextIndex <= lastEditableFieldIndex {
            setFieldActive(nextIndex)
            if nextIndex == 1 { isShowingPassportList = true }
            else if nextIndex == 2 { isShowingCountryList = true }
        } else {
            currentFieldIndex = lastEditableFieldIndex + 1
            focusedField = nil
            dismissKeyboard()
        }
    }
    
    private func saveVisa() {
        Task {
            let newVisa = Visa(
                customName: customName,
                passport: selectedPassport,
                issuingCountry: issuingCountry ?? "Unknown", // Сохраняем код страны
                entriesCount: isUnlimitedEntries ? -1 : Int(entriesCount) ?? 1,
                issueDate: Date(),
                startDate: startDate ?? Date(),
                endDate: endDate ?? Date(),
                validityPeriod: isUnlimitedStay ? -1 : (Int(stayDuration) ?? 0)
            )
            modelContext.insert(newVisa)
            do {
                try await modelContext.save()
                isShowingAddVisaView = false
            } catch {}
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func handleFocusChange(_ newValue: String?, scrollProxy: ScrollViewProxy) {
        if let newValue, currentFieldIndex != fieldIndex(for: newValue) {
            setFieldActive(fieldIndex(for: newValue))
        }
        if newValue == nil && allFieldsFilled {
            withAnimation { scrollProxy.scrollTo("saveButton", anchor: .center) }
        }
    }
    
    private func handleEntriesToggle(_ newValue: Bool) {
        if newValue {
            if currentFieldIndex == 3 { setFieldActive(4) }
            entriesCount = ""
        } else {
            setFieldActive(3)
            entriesCount = ""
        }
    }
    
    private func handleStayToggle(_ newValue: Bool) {
        if newValue {
            if currentFieldIndex == 6 { setFieldActive(5) }
            stayDuration = ""
        } else {
            setFieldActive(6)
            stayDuration = ""
        }
    }
}
