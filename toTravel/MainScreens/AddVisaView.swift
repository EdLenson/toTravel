import SwiftUI
import SwiftData

// MARK: - AddVisaView
struct AddVisaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var passports: [Passport]
    @Binding var isShowingAddVisaView: Bool
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var customName = ""
    @State private var selectedPassport: Passport?
    @State private var issuingCountry: String?
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
    @State private var showPassportExpiryError = false
    
    private var minimumDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var lastEditableFieldIndex: Int { isUnlimitedStay ? 5 : 6 }
    
    @State private var startDateFieldView: UnderlinedDateField?
    @State private var endDateFieldView: UnderlinedDateField?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    formContent
                        .padding(.horizontal, 16)
                }
                .navigationTitle(NSLocalizedString("Добавить визу", comment: "Add visa view title"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: closeButton)
                .safeAreaInset(edge: .bottom) { bottomButton }
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
    
    // MARK: - Visa Fields
    private var visaNameField: some View {
        UnderlinedTextField(
            title: NSLocalizedString("Название визы", comment: "Visa name field title"),
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
    
    private var passportField: some View {
        UnderlinedSelectionField(
            title: NSLocalizedString("Паспорт", comment: "Passport field title"),
            selectedValue: Binding(get: { selectedPassport?.customName }, set: { _ in }),
            isActive: currentFieldIndex == 1,
            action: { setFieldActive(1); isShowingPassportList = true },
            onSelection: {}
        )
        .actionSheet(isPresented: $isShowingPassportList) {
            ActionSheet(
                title: Text(NSLocalizedString("Выберите паспорт", comment: "Action sheet title for passport selection")),
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
            title: NSLocalizedString("Страна выдачи", comment: "Issuing country field label"),
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
                UnderlinedTextField(
                    title: NSLocalizedString("Количество въездов", comment: "Number of entries field label"),
                    text: Binding(
                        get: { entriesCount },
                        set: {
                            let filtered = $0.filter { $0.isNumber }
                            entriesCount = String(filtered.prefix(3))
                        }
                    )
                )
                .focused($focusedField, equals: "entriesCount")
                .keyboardType(.numberPad)
                .submitLabel(.next)
                .onTapGesture { setFieldActive(3) }
                .onSubmit { moveToNextField() }
            }
            CustomCheckbox(
                isChecked: $isUnlimitedEntries,
                title: NSLocalizedString("Неограниченное количество", comment: "Unlimited entries toggle")
            )
            .onChange(of: isUnlimitedEntries) { _, newValue in // Обновлено для iOS 17+
                handleEntriesToggle(newValue)
            }
        }
    }
    
    private var startDateField: some View {
        UnderlinedDateField(
            title: NSLocalizedString("Дата начала действия", comment: "Start date field label"),
            date: $startDate,
            dateString: $startDateString,
            oppositeDate: endDate,
            isStartDate: true
        )
        .focused($focusedField, equals: "startDate")
        .submitLabel(.next)
        .onTapGesture { setFieldActive(4) }
        .onSubmit { moveToNextField() }
        .background(GeometryReader { _ in
            Color.clear.onAppear {
                startDateFieldView = UnderlinedDateField(
                    title: NSLocalizedString("Дата начала действия", comment: "Start date field label"),
                    date: $startDate,
                    dateString: $startDateString,
                    oppositeDate: endDate,
                    isStartDate: true
                )
            }
        })
    }
    
    private var endDateField: some View {
        UnderlinedDateField(
            title: NSLocalizedString("Дата окончания действия", comment: "End date field title"),
            date: $endDate,
            dateString: $endDateString,
            minimumDate: startDate,
            oppositeDate: startDate,
            isStartDate: false
        )
        .focused($focusedField, equals: "endDate")
        .submitLabel(.next)
        .onTapGesture { setFieldActive(5) }
        .onSubmit { moveToNextField() }
        .background(GeometryReader { _ in
            Color.clear.onAppear {
                endDateFieldView = UnderlinedDateField(
                    title: NSLocalizedString("Дата окончания действия", comment: "End date field title"),
                    date: $endDate,
                    dateString: $endDateString,
                    minimumDate: startDate,
                    oppositeDate: startDate,
                    isStartDate: false
                )
            }
        })
    }
    
    private var stayDurationSection: some View {
        Group {
            if !isUnlimitedStay {
                UnderlinedTextField(
                    title: NSLocalizedString("Продолжительность пребывания", comment: "Validity period field label"),
                    text: Binding(
                        get: { stayDuration },
                        set: {
                            let filtered = $0.filter { $0.isNumber }
                            if let value = Int(filtered), value <= 366 {
                                stayDuration = String(value)
                            } else if filtered.isEmpty {
                                stayDuration = ""
                            } else {
                                stayDuration = "366"
                            }
                        }
                    )
                )
                .focused($focusedField, equals: "stayDuration")
                .keyboardType(.numberPad)
                .submitLabel(.done)
                .onTapGesture { setFieldActive(6) }
                .onSubmit { moveToNextField() }
            }
            CustomCheckbox(
                isChecked: $isUnlimitedStay,
                title: NSLocalizedString("Неограниченно", comment: "Unlimited validity period or entries")
            )
            .onChange(of: isUnlimitedStay) { _, newValue in // Обновлено для iOS 17+
                handleStayToggle(newValue)
            }
        }
    }
    
    // MARK: - Buttons
    private var saveButton: some View {
        VStack {
            if showPassportExpiryError {
                Text(NSLocalizedString("Срок действия визы не может быть дольше срока действия паспорта", comment: "Passport expiry error"))
                    .foregroundColor(Theme.Colors.expiring(for: colorScheme))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if allFieldsFilledExceptDates && currentFieldIndex > lastEditableFieldIndex {
                Button(action: saveVisa) {
                    Text(NSLocalizedString("Сохранить", comment: "Save button title"))
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.primary(for: colorScheme))
                        .foregroundColor(Theme.Colors.textInverse)
                        .cornerRadius(Theme.Tiles.cornerRadius)
                }
                .padding(.top, 16)
                .id("saveButton")
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var closeButton: some View {
        Button(NSLocalizedString("Закрыть", comment: "Close button title")) {
            isShowingAddVisaView = false
        }
        .foregroundColor(Theme.Colors.secondary(for: colorScheme))
    }
    
    private var bottomButton: some View {
        Group {
            if (focusedField != nil || (currentFieldIndex >= 0 && currentFieldIndex <= lastEditableFieldIndex)) && !isSelectionField {
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
    private var allFieldsFilledExceptDates: Bool {
        !customName.isEmpty &&
        selectedPassport != nil &&
        issuingCountry != nil &&
        (isUnlimitedEntries || !entriesCount.isEmpty) &&
        startDateString.count == 10 &&
        endDateString.count == 10 &&
        (isUnlimitedStay || (!stayDuration.isEmpty && Int(stayDuration) != nil))
    }
    
    private var isSelectionField: Bool {
        currentFieldIndex == 1 || currentFieldIndex == 2
    }
    
    // MARK: - Helper Functions
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
            if startDate == nil && startDateString.count == 10 {
                startDateFieldView?.triggerShake()
                return
            }
            if endDate == nil && endDateString.count == 10 {
                endDateFieldView?.triggerShake()
                return
            }
            
            if let end = endDate, let passport = selectedPassport, end > passport.expiryDate {
                showPassportExpiryError = true
                endDateFieldView?.triggerShake()
                return
            }
            showPassportExpiryError = false
            
            let newVisa = Visa(
                customName: customName,
                passport: selectedPassport,
                issuingCountry: issuingCountry ?? "Unknown",
                entriesCount: isUnlimitedEntries ? -1 : Int(entriesCount) ?? 1,
                issueDate: Date(),
                startDate: startDate ?? Date(),
                endDate: endDate ?? Date(),
                validityPeriod: isUnlimitedStay ? -1 : (Int(stayDuration) ?? 0)
            )
            modelContext.insert(newVisa)
            do {
                try modelContext.save() // Убрано await
                NotificationManager.shared.scheduleVisaNotifications(for: newVisa)
                isShowingAddVisaView = false
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
        if newValue == nil && allFieldsFilledExceptDates {
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
