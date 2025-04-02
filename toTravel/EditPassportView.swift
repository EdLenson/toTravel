import SwiftUI
import SwiftData

struct EditPassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isShowingEditPassportView: Bool
    var passport: Passport
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    private let originalCustomName: String
    private let originalPassportType: String
    private let originalIssuingCountry: String
    private let originalExpiryDate: Date
    private let originalIsUnlimitedExpiry: Bool
    
    @State private var customName: String
    @State private var passportType: String
    @State private var issuingCountry: String // Хранит код страны (cca2)
    @State private var expiryDate: Date?
    @State private var expiryDateString: String
    @State private var isUnlimitedExpiry: Bool
    @State private var isShowingCountryList = false
    @State private var isShowingPassportTypePicker = false
    @State private var currentFieldIndex = -1
    @FocusState private var focusedField: String?
    
    private var minimumDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var lastEditableFieldIndex: Int { isUnlimitedExpiry ? 2 : 3 }
    
    init(isShowingEditPassportView: Binding<Bool>, passport: Passport) {
        self._isShowingEditPassportView = isShowingEditPassportView
        self.passport = passport
        self._customName = State(initialValue: passport.customName)
        self._passportType = State(initialValue: passport.type)
        self._issuingCountry = State(initialValue: passport.issuingCountry)
        self._expiryDate = State(initialValue: passport.expiryDate)
        self._expiryDateString = State(initialValue: {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return passport.expiryDate == Date.distantFuture ? "" : formatter.string(from: passport.expiryDate)
        }())
        self._isUnlimitedExpiry = State(initialValue: passport.expiryDate >= Date.distantFuture)
        
        self.originalCustomName = passport.customName
        self.originalPassportType = passport.type
        self.originalIssuingCountry = passport.issuingCountry
        self.originalExpiryDate = passport.expiryDate
        self.originalIsUnlimitedExpiry = passport.expiryDate >= Date.distantFuture
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    formContent
                        .padding(.horizontal, 16)
                }
                .navigationTitle("Редактировать паспорт")
                .navigationBarItems(trailing: closeButton)
                .safeAreaInset(edge: .bottom) { nextButtonView }
                .onTapGesture { dismissKeyboard(); currentFieldIndex = -1; focusedField = nil }
                .onChange(of: focusedField) { handleFocusChange($0, scrollProxy: scrollProxy) }
            }
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 20) {
            passportFieldsView
            toggleView
            saveButtonView
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private var passportFieldsView: some View {
        VStack(spacing: 20) {
            customNameField
            passportTypeField
            issuingCountryField
            if !isUnlimitedExpiry { expiryDateField }
        }
    }
    
    private var customNameField: some View {
        UnderlinedTextField(title: "Название паспорта", text: $customName)
            .focused($focusedField, equals: "customName")
            .submitLabel(.next)
            .onTapGesture { setFieldActive(0) }
            .onSubmit { moveToNextField() }
    }
    
    private var passportTypeField: some View {
        UnderlinedSelectionField(
            title: "Тип паспорта",
            selectedValue: Binding(get: { passportType.isEmpty ? nil : passportType }, set: { _ in }),
            isActive: currentFieldIndex == 1,
            action: { setFieldActive(1); isShowingPassportTypePicker = true },
            onSelection: {}
        )
        .actionSheet(isPresented: $isShowingPassportTypePicker) {
            ActionSheet(
                title: Text("Выберите тип паспорта"),
                buttons: [
                    .default(Text("Внутренний")) { passportType = "Внутренний"; moveToNextField() },
                    .default(Text("Заграничный")) { passportType = "Заграничный"; moveToNextField() },
                    .cancel()
                ]
            )
        }
    }
    
    private var issuingCountryField: some View {
        UnderlinedSelectionField(
            title: "Страна выдачи",
            selectedValue: Binding(
                get: { issuingCountry.isEmpty ? nil : countriesManager.getName(forCode: issuingCountry) },
                set: { _ in }
            ),
            isActive: currentFieldIndex == 2,
            action: { setFieldActive(2); isShowingCountryList = true },
            onSelection: {}
        )
        .sheet(isPresented: $isShowingCountryList) {
            CountryList(selectedCountry: Binding(
                get: { issuingCountry.isEmpty ? "" : countriesManager.getName(forCode: issuingCountry) },
                set: { issuingCountry = countriesManager.getCode(for: $0) ?? "Unknown"; moveToNextField() }
            ), isShowing: $isShowingCountryList)
        }
    }
    
    private var expiryDateField: some View {
        UnderlinedDateField(
            title: "Срок действия",
            date: $expiryDate,
            dateString: $expiryDateString,
            minimumDate: minimumDate
        )
        .focused($focusedField, equals: "expiryDate")
        .submitLabel(.done)
        .onTapGesture { setFieldActive(3) }
        .onSubmit { moveToNextField() }
    }
    
    private var toggleView: some View {
        CustomCheckbox(isChecked: $isUnlimitedExpiry, title: "Бессрочный")
            .onChange(of: isUnlimitedExpiry) { handleToggleChange($0) }
    }
    
    private var saveButtonView: some View {
        Group {
            if hasChanges && allFieldsFilled && focusedField == nil {
                Button(action: savePassport) {
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
        Button("Закрыть") { isShowingEditPassportView = false }
    }
    
    private var nextButtonView: some View {
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
        !passportType.isEmpty &&
        !issuingCountry.isEmpty &&
        (isUnlimitedExpiry || (expiryDate != nil && expiryDateString.count == 10))
    }
    
    private var hasChanges: Bool {
        customName != originalCustomName ||
        passportType != originalPassportType ||
        issuingCountry != originalIssuingCountry ||
        isUnlimitedExpiry != originalIsUnlimitedExpiry ||
        (!isUnlimitedExpiry && expiryDate != originalExpiryDate)
    }
    
    private func fieldIndex(for field: String) -> Int {
        switch field {
        case "customName": return 0
        case "passportType": return 1
        case "issuingCountry": return 2
        case "expiryDate": return 3
        default: return -1
        }
    }
    
    private var isSelectionField: Bool {
        currentFieldIndex == 1 || currentFieldIndex == 2
    }
    
    private func setFieldActive(_ index: Int) {
        guard index >= 0 && index <= lastEditableFieldIndex else { return }
        currentFieldIndex = index
        focusedField = ["customName", "passportType", "issuingCountry", "expiryDate"][index]
        if index == 1 || index == 2 { dismissKeyboard() }
    }
    
    private func moveToNextField() {
        let nextIndex = currentFieldIndex + 1
        if currentFieldIndex < 0 { setFieldActive(0); return }
        if nextIndex <= lastEditableFieldIndex {
            setFieldActive(nextIndex)
            if nextIndex == 1 { isShowingPassportTypePicker = true }
            else if nextIndex == 2 { isShowingCountryList = true }
        } else {
            currentFieldIndex = lastEditableFieldIndex + 1
            focusedField = nil
            dismissKeyboard()
        }
    }
    
    private func savePassport() {
        Task {
            passport.customName = customName
            passport.type = passportType
            passport.issuingCountry = issuingCountry // Сохраняем код страны
            passport.expiryDate = isUnlimitedExpiry ? Date.distantFuture : (expiryDate ?? Date())
            do {
                try await modelContext.save()
                isShowingEditPassportView = false
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
        if newValue == nil && hasChanges && allFieldsFilled {
            withAnimation { scrollProxy.scrollTo("saveButton", anchor: .center) }
        }
    }
    
    private func handleToggleChange(_ newValue: Bool) {
        if newValue {
            if currentFieldIndex == 3 {
                currentFieldIndex = lastEditableFieldIndex + 1
                focusedField = nil
                dismissKeyboard()
            }
            expiryDate = nil
            expiryDateString = ""
        } else {
            setFieldActive(3)
            expiryDate = nil
            expiryDateString = ""
        }
    }
}

#Preview {
    EditPassportView(
        isShowingEditPassportView: .constant(true),
        passport: Passport(customName: "Test", issuingCountry: "RU", expiryDate: Date(), type: "Заграничный")
    )
}
