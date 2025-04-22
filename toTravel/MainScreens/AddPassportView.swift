import SwiftUI
import SwiftData

// MARK: - AddPassportView
struct AddPassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isShowingAddPassportView: Bool
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var shakeCustomName = false
    @State private var customName = ""
    @State private var issuingCountry: String?
    @State private var expiryDate: Date?
    @State private var expiryDateString = ""
    @State private var isUnlimitedExpiry = false
    @State private var isShowingCountryList = false
    @State private var currentFieldIndex = -1
    @FocusState private var focusedField: String?
    
    private var minimumDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var lastEditableFieldIndex: Int { isUnlimitedExpiry ? 1 : 2 }
    
    @State private var expiryDateFieldView: UnderlinedDateField? // Для вызова triggerShake
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    formContent
                        .padding(.horizontal, 16)
                }
                .navigationTitle(NSLocalizedString("Добавить паспорт", comment: "Add passport view title"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: closeButton)
                .safeAreaInset(edge: .bottom) { nextButtonView }
                .onTapGesture { dismissKeyboard(); currentFieldIndex = -1; focusedField = nil }
                .onChange(of: focusedField) { _, newValue in // Обновлено для iOS 17+
                    handleFocusChange(newValue, scrollProxy: scrollProxy)
                }
            }
            .background(Theme.Colors.background(for: colorScheme))
        }
    }
    
    // MARK: - Form Content
    private var formContent: some View {
        VStack(spacing: 20) {
            passportFieldsView
            toggleView
            saveButtonView
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Passport Fields
    private var passportFieldsView: some View {
        VStack(spacing: 20) {
            customNameField
            issuingCountryField
            if !isUnlimitedExpiry { expiryDateField }
        }
    }
    
    private var customNameField: some View {
        UnderlinedTextField(
            title: NSLocalizedString("Название паспорта", comment: "Passport name field title"),
            text: Binding(
                get: { customName },
                set: { customName = String($0.prefix(30)) }
            )
        )
        .focused($focusedField, equals: "customName")
        .submitLabel(.next)
        .onTapGesture { setFieldActive(0) }
        .onSubmit { moveToNextField() }
    }
    
    private var issuingCountryField: some View {
        UnderlinedSelectionField(
            title: NSLocalizedString("Страна выдачи", comment: "Issuing country field label"),
            selectedValue: Binding(
                get: { issuingCountry != nil ? countriesManager.getName(forCode: issuingCountry!) : nil },
                set: { _ in }
            ),
            isActive: currentFieldIndex == 1,
            action: { setFieldActive(1); isShowingCountryList = true },
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
            title: NSLocalizedString("Срок действия", comment: "Expiration date field label"),
            date: $expiryDate,
            dateString: $expiryDateString,
            minimumDate: minimumDate,
            oppositeDate: nil,
            isStartDate: false
        )
        .focused($focusedField, equals: "expiryDate")
        .submitLabel(.done)
        .onTapGesture { setFieldActive(2) }
        .onSubmit { moveToNextField() }
        .background(GeometryReader { _ in
            Color.clear.onAppear {
                expiryDateFieldView = UnderlinedDateField(
                    title: NSLocalizedString("Срок действия", comment: "Expiration date field label"),
                    date: $expiryDate,
                    dateString: $expiryDateString,
                    minimumDate: minimumDate,
                    oppositeDate: nil,
                    isStartDate: false
                )
            }
        })
    }
    
    // MARK: - Toggle and Buttons
    private var toggleView: some View {
        CustomCheckbox(
            isChecked: $isUnlimitedExpiry,
            title: NSLocalizedString("Бессрочный", comment: "Unlimited expiry toggle")
        )
        .onChange(of: isUnlimitedExpiry) { _, newValue in // Обновлено для iOS 17+
            handleToggleChange(newValue)
        }
    }
    
    private var saveButtonView: some View {
        Group {
            if allFieldsFilledExceptDate && currentFieldIndex > lastEditableFieldIndex {
                Button(action: savePassport) {
                    Text(NSLocalizedString("Сохранить", comment: "Save button title"))
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.primary(for: colorScheme))
                        .foregroundColor(Theme.Colors.textInverse)
                        .cornerRadius(Theme.Tiles.cornerRadius)
                }
                .padding(.top, 20)
                .buttonStyle(PlainButtonStyle())
                .id("saveButton")
            }
        }
    }
    
    private var closeButton: some View {
        Button(NSLocalizedString("Закрыть", comment: "Close button title")) {
            isShowingAddPassportView = false
        }
        .foregroundColor(Theme.Colors.secondary(for: colorScheme))
    }
    
    private var nextButtonView: some View {
        Group {
            if focusedField != nil || (currentFieldIndex >= 0 && currentFieldIndex <= lastEditableFieldIndex) {
                HStack {
                    Spacer()
                    Button(action: moveToNextField) {
                        Text(currentFieldIndex == lastEditableFieldIndex ?
                            NSLocalizedString("Готово", comment: "Done button title") :
                            NSLocalizedString("Далее", comment: "Next button title")
                        )
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primary(for: colorScheme))
                        .foregroundColor(Theme.Colors.textInverse)
                        .cornerRadius(Theme.Tiles.cornerRadius)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Computed Properties
    private var allFieldsFilledExceptDate: Bool {
        !customName.isEmpty &&
        issuingCountry != nil &&
        (isUnlimitedExpiry || expiryDateString.count == 10)
    }
    
    // MARK: - Helper Functions
    private func fieldIndex(for field: String) -> Int {
        switch field {
        case "customName": return 0
        case "issuingCountry": return 1
        case "expiryDate": return 2
        default: return -1
        }
    }
    
    private func setFieldActive(_ index: Int) {
        guard index >= 0 && index <= lastEditableFieldIndex else { return }
        currentFieldIndex = index
        focusedField = ["customName", "issuingCountry", "expiryDate"][index]
        if index == 1 { dismissKeyboard() }
    }
    
    private func moveToNextField() {
        let nextIndex = currentFieldIndex + 1
        if currentFieldIndex < 0 || nextIndex <= lastEditableFieldIndex {
            setFieldActive(min(nextIndex, lastEditableFieldIndex))
            if nextIndex == 1 { isShowingCountryList = true }
        } else {
            currentFieldIndex = lastEditableFieldIndex + 1
            focusedField = nil
            dismissKeyboard()
        }
    }
    
    private func savePassport() {
        if !isUnlimitedExpiry && expiryDate == nil && expiryDateString.count == 10 {
            expiryDateFieldView?.triggerShake()
            return
        }
        
        let newPassport = Passport(
            customName: customName,
            issuingCountry: issuingCountry ?? "Unknown",
            expiryDate: isUnlimitedExpiry ? Date.distantFuture : (expiryDate ?? Date())
        )
        modelContext.insert(newPassport)
        Task {
            do {
                try modelContext.save() // Убрано await, так как save() синхронный в данном контексте
                NotificationManager.shared.schedulePassportNotifications(for: newPassport)
                isShowingAddPassportView = false
            } catch {
                // Обработка ошибки, если нужно
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func handleFocusChange(_ newValue: String?, scrollProxy: ScrollViewProxy) {
        if let newValue, currentFieldIndex != fieldIndex(for: newValue) {
            setFieldActive(fieldIndex(for: newValue))
        }
        if newValue == nil && allFieldsFilledExceptDate {
            withAnimation { scrollProxy.scrollTo("saveButton", anchor: .center) }
        }
    }
    
    private func handleToggleChange(_ newValue: Bool) {
        if newValue {
            if currentFieldIndex == 2 {
                currentFieldIndex = lastEditableFieldIndex + 1
                focusedField = nil
                dismissKeyboard()
            }
            expiryDate = nil
            expiryDateString = ""
        } else {
            setFieldActive(2)
            expiryDate = nil
            expiryDateString = ""
        }
    }
}

// MARK: - Preview
#Preview {
    AddPassportView(isShowingAddPassportView: .constant(true))
}
