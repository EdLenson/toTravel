// AddVisaView.swift
// toTravel
// Created by Ed on 3/21/25.

import SwiftUI
import SwiftData

struct AddVisaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var passports: [Passport]
    @Binding var isShowingAddVisaView: Bool
    
    @State private var customName: String = ""
    @State private var selectedPassport: Passport?
    @State private var issuingCountry: String?
    @State private var entriesCount: String = ""
    @State private var isUnlimitedEntries: Bool = false
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var startDateString: String = ""
    @State private var endDateString: String = ""
    @State private var stayDuration: String = ""
    @State private var isUnlimitedStay: Bool = false
    @State private var isShowingCountryList: Bool = false
    @State private var isShowingPassportList: Bool = false
    @State private var currentFieldIndex: Int = -1
    
    @FocusState private var focusedField: String?
    
    private var minimumDate: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var lastEditableFieldIndex: Int {
        if isUnlimitedStay {
            return 5 // "Дата окончания действия" (5), если "Неограниченно" активно
        }
        return 6 // "Продолжительность пребывания" (6), если "Неограниченно" не активно
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
    
    private var isSelectionField: Bool {
        currentFieldIndex == fieldIndex(for: "passport") || currentFieldIndex == fieldIndex(for: "issuingCountry")
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        UnderlinedTextField(title: "Название визы", text: $customName)
                            .focused($focusedField, equals: "customName")
                            .submitLabel(.next)
                            .onTapGesture { setFieldActive(fieldIndex(for: "customName")) }
                            .onSubmit { moveToNextField() }
                        
                        UnderlinedSelectionField(
                            title: "Паспорт",
                            selectedValue: Binding(get: { selectedPassport?.customName }, set: { _ in }),
                            isActive: currentFieldIndex == fieldIndex(for: "passport"),
                            action: {
                                setFieldActive(fieldIndex(for: "passport"))
                                isShowingPassportList = true
                            },
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
                        
                        UnderlinedSelectionField(
                            title: "Страна выдачи",
                            selectedValue: $issuingCountry,
                            isActive: currentFieldIndex == fieldIndex(for: "issuingCountry"),
                            action: {
                                setFieldActive(fieldIndex(for: "issuingCountry"))
                                isShowingCountryList = true
                            },
                            onSelection: {}
                        )
                        .sheet(isPresented: $isShowingCountryList) {
                            CountryList(selectedCountry: Binding(
                                get: { issuingCountry ?? "" },
                                set: {
                                    issuingCountry = $0
                                    moveToNextField()
                                }
                            ), isShowing: $isShowingCountryList)
                        }
                        
                        if !isUnlimitedEntries {
                            UnderlinedTextField(title: "Количество въездов", text: $entriesCount)
                                .focused($focusedField, equals: "entriesCount")
                                .keyboardType(.numberPad)
                                .submitLabel(.next)
                                .onTapGesture { setFieldActive(fieldIndex(for: "entriesCount")) }
                                .onSubmit { moveToNextField() }
                        }
                        
                        Toggle("Неограниченное количество", isOn: $isUnlimitedEntries)
                            .padding(.horizontal)
                            .onChange(of: isUnlimitedEntries) { newValue in
                                if newValue {
                                    if currentFieldIndex == fieldIndex(for: "entriesCount") {
                                        setFieldActive(fieldIndex(for: "startDate"))
                                    }
                                    entriesCount = ""
                                } else {
                                    // При выключении возвращаем фокус в "Количество въездов"
                                    setFieldActive(fieldIndex(for: "entriesCount"))
                                    entriesCount = ""
                                }
                            }
                        
                        UnderlinedDateField(
                            title: "Дата начала действия",
                            date: $startDate,
                            dateString: $startDateString
                        )
                        .focused($focusedField, equals: "startDate")
                        .submitLabel(.next)
                        .onTapGesture { setFieldActive(fieldIndex(for: "startDate")) }
                        .onSubmit { moveToNextField() }
                        
                        UnderlinedDateField(
                            title: "Дата окончания действия",
                            date: $endDate,
                            dateString: $endDateString,
                            minimumDate: startDate
                        )
                        .focused($focusedField, equals: "endDate")
                        .submitLabel(.next)
                        .onTapGesture { setFieldActive(fieldIndex(for: "endDate")) }
                        .onSubmit { moveToNextField() }
                        
                        if !isUnlimitedStay {
                            UnderlinedTextField(title: "Продолжительность пребывания", text: $stayDuration)
                                .focused($focusedField, equals: "stayDuration")
                                .keyboardType(.numberPad)
                                .submitLabel(.done)
                                .onTapGesture { setFieldActive(fieldIndex(for: "stayDuration")) }
                                .onSubmit { moveToNextField() }
                        }
                        
                        Toggle("Неограниченно", isOn: $isUnlimitedStay)
                            .padding(.horizontal)
                            .onChange(of: isUnlimitedStay) { newValue in
                                if newValue {
                                    if currentFieldIndex == fieldIndex(for: "stayDuration") {
                                        setFieldActive(fieldIndex(for: "endDate"))
                                    }
                                    stayDuration = ""
                                } else {
                                    // При выключении возвращаем фокус в "Продолжительность пребывания"
                                    setFieldActive(fieldIndex(for: "stayDuration"))
                                    stayDuration = ""
                                }
                            }
                        
                        if allFieldsFilled && currentFieldIndex > lastEditableFieldIndex {
                            Button(action: saveVisa) {
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
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .navigationTitle("Добавить визу")
                .navigationBarItems(trailing: Button("Закрыть") {
                    isShowingAddVisaView = false
                })
                .safeAreaInset(edge: .bottom) {
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
                .onTapGesture {
                    dismissKeyboard()
                    currentFieldIndex = -1
                    focusedField = nil
                }
                .onChange(of: focusedField) { newValue in
                    if let newValue = newValue, currentFieldIndex != fieldIndex(for: newValue) {
                        setFieldActive(fieldIndex(for: newValue))
                    }
                    if newValue == nil && allFieldsFilled {
                        withAnimation {
                            scrollProxy.scrollTo("saveButton", anchor: .center)
                        }
                    }
                }
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
    
    private func setFieldActive(_ index: Int) {
        guard index >= 0 && index <= lastEditableFieldIndex else { return }
        currentFieldIndex = index
        let field: String
        switch index {
        case 0: field = "customName"
        case 1: field = "passport"
        case 2: field = "issuingCountry"
        case 3: field = "entriesCount"
        case 4: field = "startDate"
        case 5: field = "endDate"
        case 6: field = "stayDuration"
        default: return
        }
        focusedField = field
        if field == "passport" || field == "issuingCountry" {
            dismissKeyboard()
        }
    }
    
    private func moveToNextField() {
        if currentFieldIndex < 0 { // Если фокус не установлен
            setFieldActive(0)
            return
        }
        
        var nextIndex = currentFieldIndex + 1
        
        // Пропускаем "Количество въездов", если isUnlimitedEntries == true
        if isUnlimitedEntries && nextIndex == fieldIndex(for: "entriesCount") {
            nextIndex += 1
        }
        
        // Пропускаем "Продолжительность пребывания", если isUnlimitedStay == true
        if isUnlimitedStay && nextIndex == fieldIndex(for: "stayDuration") {
            nextIndex += 1
        }
        
        // Если следующий индекс в пределах допустимого, устанавливаем фокус
        if nextIndex <= lastEditableFieldIndex {
            setFieldActive(nextIndex)
            if nextIndex == fieldIndex(for: "passport") {
                isShowingPassportList = true
            } else if nextIndex == fieldIndex(for: "issuingCountry") {
                isShowingCountryList = true
            }
        } else {
            // Достигли последнего поля, сбрасываем фокус
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
                issuingCountry: issuingCountry ?? "",
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
            } catch {
                print("Ошибка сохранения визы: \(error.localizedDescription)")
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
