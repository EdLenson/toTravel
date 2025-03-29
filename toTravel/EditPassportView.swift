import SwiftUI
import SwiftData

struct EditPassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isShowingEditPassportView: Bool
    var passport: Passport
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    // Исходные значения
    private let originalCustomName: String
    private let originalPassportType: String
    private let originalIssuingCountry: String
    private let originalExpiryDate: Date
    private let originalIsUnlimitedExpiry: Bool
    
    // Состояния
    @State private var customName: String
    @State private var passportType: String
    @State private var issuingCountry: String
    @State private var expiryDate: Date?
    @State private var expiryDateString: String
    @State private var isUnlimitedExpiry: Bool
    @State private var isShowingCountryList: Bool = false
    @State private var isShowingPassportTypePicker: Bool = false
    @State private var currentFieldIndex: Int = -1
    
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
                    VStack(spacing: 20) {
                        passportFieldsView
                        toggleView
                        saveButtonView(scrollProxy: scrollProxy)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .navigationTitle("Редактировать паспорт")
                .navigationBarItems(trailing: Button("Закрыть") { isShowingEditPassportView = false })
                .safeAreaInset(edge: .bottom) { nextButtonView }
                .onTapGesture { dismissKeyboard(); currentFieldIndex = -1; focusedField = nil }
                .onChange(of: focusedField) { newValue in handleFocusChange(newValue, scrollProxy: scrollProxy) }
            }
        }
    }
    
    // MARK: - Подкомпоненты
    
    private var passportFieldsView: some View {
        VStack(spacing: 20) {
            UnderlinedTextField(title: "Название паспорта", text: $customName)
                .focused($focusedField, equals: "customName")
                .submitLabel(.next)
                .onTapGesture { setFieldActive(fieldIndex(for: "customName")) }
                .onSubmit { moveToNextField() }
            
            passportTypeField
            issuingCountryField
            if !isUnlimitedExpiry { expiryDateField }
        }
    }
    
    private var passportTypeField: some View {
        UnderlinedSelectionField(
            title: "Тип паспорта",
            selectedValue: Binding(get: { passportType.isEmpty ? nil : passportType }, set: { _ in }),
            isActive: currentFieldIndex == fieldIndex(for: "passportType"),
            action: {
                setFieldActive(fieldIndex(for: "passportType"))
                isShowingPassportTypePicker = true
            },
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
            isActive: currentFieldIndex == fieldIndex(for: "issuingCountry"),
            action: {
                setFieldActive(fieldIndex(for: "issuingCountry"))
                isShowingCountryList = true
            },
            onSelection: {}
        )
        .sheet(isPresented: $isShowingCountryList) {
            CountryList(selectedCountry: Binding(
                get: { issuingCountry.isEmpty ? "" : countriesManager.getName(forCode: issuingCountry) },
                set: { issuingCountry = countriesManager.getCode(for: $0) ?? $0; moveToNextField() }
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
        .onTapGesture { setFieldActive(fieldIndex(for: "expiryDate")) }
        .onSubmit { moveToNextField() }
    }
    
    private var toggleView: some View {
        Toggle("Бессрочный", isOn: $isUnlimitedExpiry)
            .padding(.horizontal)
            .onChange(of: isUnlimitedExpiry) { newValue in
                if newValue {
                    if currentFieldIndex == fieldIndex(for: "expiryDate") {
                        currentFieldIndex = lastEditableFieldIndex + 1
                        focusedField = nil
                        dismissKeyboard()
                    }
                    expiryDate = nil
                    expiryDateString = ""
                } else {
                    setFieldActive(fieldIndex(for: "expiryDate"))
                    expiryDate = nil
                    expiryDateString = ""
                }
            }
    }
    
    private func saveButtonView(scrollProxy: ScrollViewProxy) -> some View {
        Group {
            if hasChanges && allFieldsFilled && focusedField == nil {
                Button(action: savePassport) {
                    Text("Сохранить")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .id("saveButton")
            }
        }
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Логика
    
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
        (isUnlimitedExpiry == false && expiryDate != originalExpiryDate)
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
        currentFieldIndex == fieldIndex(for: "passportType") || currentFieldIndex == fieldIndex(for: "issuingCountry")
    }
    
    private func setFieldActive(_ index: Int) {
        currentFieldIndex = index
        let field: String
        switch index {
        case 0: field = "customName"
        case 1: field = "passportType"
        case 2: field = "issuingCountry"
        case 3: field = "expiryDate"
        default: return
        }
        focusedField = field
        if field == "issuingCountry" || field == "passportType" { dismissKeyboard() }
    }
    
    private func moveToNextField() {
        let nextIndex = currentFieldIndex + 1
        if currentFieldIndex < 0 { setFieldActive(0); return }
        if nextIndex <= lastEditableFieldIndex {
            setFieldActive(nextIndex)
            if nextIndex == fieldIndex(for: "issuingCountry") { isShowingCountryList = true }
            else if nextIndex == fieldIndex(for: "passportType") { isShowingPassportTypePicker = true }
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
            passport.issuingCountry = issuingCountry
            passport.expiryDate = isUnlimitedExpiry ? Date.distantFuture : (expiryDate ?? Date())
            do {
                try await modelContext.save()
                isShowingEditPassportView = false
            } catch {
                print("Ошибка сохранения паспорта: \(error.localizedDescription)")
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func handleFocusChange(_ newValue: String?, scrollProxy: ScrollViewProxy) {
        if let newValue = newValue, currentFieldIndex != fieldIndex(for: newValue) {
            setFieldActive(fieldIndex(for: newValue))
        }
        if newValue == nil && hasChanges && allFieldsFilled {
            withAnimation { scrollProxy.scrollTo("saveButton", anchor: .center) }
        }
    }
}

#Preview {
    EditPassportView(
        isShowingEditPassportView: .constant(true),
        passport: Passport(customName: "Test", issuingCountry: "RU", expiryDate: Date(), type: "Заграничный")
    )
}
