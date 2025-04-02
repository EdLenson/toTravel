import SwiftUI
import SwiftData

struct AddPassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isShowingAddPassportView: Bool
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var customName = ""
    @State private var passportType = ""
    @State private var issuingCountry: String? // Хранит код страны (cca2)
    @State private var expiryDate: Date?
    @State private var expiryDateString = ""
    @State private var isUnlimitedExpiry = false
    @State private var isShowingCountryList = false
    @State private var isShowingPassportTypePicker = false
    @State private var currentFieldIndex = -1
    @FocusState private var focusedField: String?
    
    private var minimumDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var lastEditableFieldIndex: Int { isUnlimitedExpiry ? 2 : 3 }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    formContent
                        .padding(.horizontal, 16)
                }
                .navigationTitle("Добавить паспорт")
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
            if allFieldsFilled && currentFieldIndex > lastEditableFieldIndex {
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
        Button("Закрыть") { isShowingAddPassportView = false }
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
        guard index >= 0 && index <= lastEditableFieldIndex else { return }
        currentFieldIndex = index
        focusedField = ["customName", "passportType", "issuingCountry", "expiryDate"][index]
        if index == 1 || index == 2 { dismissKeyboard() }
    }
    
    private func moveToNextField() {
        let nextIndex = currentFieldIndex + 1
        if currentFieldIndex < 0 || nextIndex <= lastEditableFieldIndex {
            setFieldActive(min(nextIndex, lastEditableFieldIndex))
            if nextIndex == 1 { isShowingPassportTypePicker = true }
            else if nextIndex == 2 { isShowingCountryList = true }
        } else {
            currentFieldIndex = lastEditableFieldIndex + 1
            focusedField = nil
            dismissKeyboard()
        }
    }
    
    private func savePassport() {
        let newPassport = Passport(
            customName: customName,
            issuingCountry: issuingCountry ?? "Unknown", // Сохраняем код страны
            expiryDate: isUnlimitedExpiry ? Date.distantFuture : (expiryDate ?? Date()),
            type: passportType
        )
        modelContext.insert(newPassport)
        Task {
            do {
                try await modelContext.save()
                isShowingAddPassportView = false
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
    AddPassportView(isShowingAddPassportView: .constant(true))
}
