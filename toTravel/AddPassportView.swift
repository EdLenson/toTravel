import SwiftUI
import SwiftData

struct AddPassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isShowingAddPassportView: Bool
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var customName: String = ""
    @State private var passportType: String = ""
    @State private var issuingCountry: String? // Хранит ISO2-код
    @State private var expiryDate: Date?
    @State private var expiryDateString: String = ""
    @State private var isUnlimitedExpiry: Bool = false
    @State private var isShowingCountryList: Bool = false
    @State private var isShowingPassportTypePicker: Bool = false
    @State private var currentFieldIndex: Int = -1
    
    @FocusState private var focusedField: String?
    
    private var minimumDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var lastEditableFieldIndex: Int { isUnlimitedExpiry ? 2 : 3 }
    
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
                .navigationTitle("Добавить паспорт")
                .navigationBarItems(trailing: Button("Закрыть") { isShowingAddPassportView = false })
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
                get: { issuingCountry != nil ? countriesManager.getName(forCode: issuingCountry!) : nil },
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
                get: { issuingCountry != nil ? countriesManager.getName(forCode: issuingCountry!) : "" },
                set: { issuingCountry = countriesManager.getCode(for: $0); moveToNextField() }
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
            if allFieldsFilled && currentFieldIndex > lastEditableFieldIndex {
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
            if focusedField != nil || (currentFieldIndex >= 0 && currentFieldIndex <= lastEditableFieldIndex) {
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
        issuingCountry != nil &&
        (isUnlimitedExpiry || (expiryDate != nil && expiryDateString.count == 10))
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
        if currentFieldIndex < 0 || nextIndex <= lastEditableFieldIndex {
            setFieldActive(min(nextIndex, lastEditableFieldIndex))
            if nextIndex == fieldIndex(for: "issuingCountry") { isShowingCountryList = true }
            else if nextIndex == fieldIndex(for: "passportType") { isShowingPassportTypePicker = true }
        } else {
            currentFieldIndex = lastEditableFieldIndex + 1
            focusedField = nil
            dismissKeyboard()
        }
    }
    
    private func savePassport() {
        let newPassport = Passport(
            customName: customName,
            issuingCountry: issuingCountry ?? "",
            expiryDate: isUnlimitedExpiry ? Date.distantFuture : (expiryDate ?? Date()),
            type: passportType
        )
        modelContext.insert(newPassport)
        Task {
            do {
                try await modelContext.save()
                isShowingAddPassportView = false
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
        if newValue == nil && allFieldsFilled {
            withAnimation { scrollProxy.scrollTo("saveButton", anchor: .center) }
        }
    }
}

#Preview {
    AddPassportView(isShowingAddPassportView: .constant(true))
}
