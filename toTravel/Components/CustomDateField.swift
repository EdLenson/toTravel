import SwiftUI

extension String {
    func containsCharacter(_ character: Character, at index: Index) -> Bool {
        guard index < endIndex else { return false }
        return self[index] == character
    }
}

// MARK: - UnderlinedDateField View
struct UnderlinedDateField: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    @Binding var date: Date?
    var dateString: Binding<String>? = nil
    var minimumDate: Date? = nil
    var oppositeDate: Date? = nil
    var isStartDate: Bool = false
    
    @State private var internalDateString: String = ""
    @State private var isEditing: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var hasValidationError: Bool = false // Только для 29 февраля в невисокосный год
    
    private var activeDateString: Binding<String> {
        dateString ?? $internalDateString
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                Text(title)
                    .font(Theme.Fonts.countryTitle)
                    .foregroundColor(hasValidationError ? Theme.Colors.expiring : (isEditing ? Theme.Colors.primary : Theme.Colors.secondary))
                    .offset(y: isEditing || !activeDateString.wrappedValue.isEmpty ? -25 : 0)
                    .scaleEffect(isEditing || !activeDateString.wrappedValue.isEmpty ? 0.8 : 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.2), value: isEditing || !activeDateString.wrappedValue.isEmpty)
                
                ZStack(alignment: .leading) {
                    if isEditing && activeDateString.wrappedValue.isEmpty {
                        Text("10.01.2020")
                            .foregroundColor(Theme.Colors.secondary)
                    }
                    
                    TextField("", text: activeDateString, onEditingChanged: { editing in
                        isEditing = editing
                        if !editing {
                            updateDateFromString()
                        }
                    })
                    .keyboardType(.numberPad)
                    .foregroundColor(.primary)
                    .onChange(of: activeDateString.wrappedValue) { oldValue, newValue in // Обновлено для iOS 17+
                        let (validatedString, isValid) = formatAndValidateDateString(newValue)
                        activeDateString.wrappedValue = validatedString
                        
                        if !isValid {
                            triggerShake()
                        }
                        
                        if activeDateString.wrappedValue.count == 10 {
                            updateDateFromString()
                        } else {
                            date = nil
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .frame(height: isEditing ? 2 : 1)
                    .foregroundColor(isEditing ? Theme.Colors.primary(for: colorScheme) : Theme.Colors.secondary(for: colorScheme).opacity(0.5)),
                alignment: .bottom
            )
            .offset(x: shakeOffset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60)
        .onAppear {
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                activeDateString.wrappedValue = formatter.string(from: date)
            }
        }
        .onChange(of: date) { oldValue, newDate in // Обновлено для iOS 17+
            if let newDate = newDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                activeDateString.wrappedValue = formatter.string(from: newDate)
            } else if activeDateString.wrappedValue.count != 10 {
                // Не сбрасываем строку, если она уже изменена
            } else {
                activeDateString.wrappedValue = ""
            }
        }
    }
    
    // MARK: - Date Formatting and Validation
    private func formatAndValidateDateString(_ input: String) -> (String, Bool) {
        var cleanInput = input
        let isDeleting = input.count < activeDateString.wrappedValue.count
        
        if !isDeleting {
            cleanInput = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        }
        
        if cleanInput.count > 8 && !isDeleting {
            cleanInput = String(cleanInput.prefix(8))
        }
                
        var resultString = ""
        var isValid = true
        
        // Обработка дня
        if cleanInput.count > 0 {
            let dayPart = String(cleanInput.prefix(2))
            if dayPart.count == 1 {
                let firstChar = dayPart.first!
                if let firstDigit = Int(String(firstChar)), firstDigit >= 4 && firstDigit <= 9 {
                    resultString = "0" + String(firstDigit)
                } else {
                    resultString = dayPart
                }
            } else if dayPart.count == 2 {
                if let dayInt = Int(dayPart), dayInt >= 1 && dayInt <= 31 {
                    resultString = dayPart
                } else {
                    resultString = String(dayPart.prefix(1))
                    isValid = false
                }
            }
        }
        
        if cleanInput.count > 2 || (isDeleting && input.contains(".") && resultString.count == 2) {
            if resultString.count == 2 && !resultString.contains(".") {
                resultString += "."
            }
        }
        
        // Обработка месяца
        if cleanInput.count > 2 {
            let monthStart = cleanInput.index(cleanInput.startIndex, offsetBy: 2)
            let monthPart = String(cleanInput[monthStart..<cleanInput.index(monthStart, offsetBy: min(2, cleanInput.count - 2))])
            
            if !monthPart.isEmpty {
                if monthPart.count == 1 {
                    let monthChar = monthPart.first!
                    if let monthDigit = Int(String(monthChar)), monthDigit >= 2 && monthDigit <= 9 {
                        resultString += "0" + String(monthDigit)
                    } else {
                        resultString += monthPart
                    }
                } else if monthPart.count == 2 {
                    if let monthInt = Int(monthPart), monthInt >= 1 && monthInt <= 12 {
                        resultString += monthPart
                        // Проверка на февраль с днями 30 или 31
                        if monthInt == 2, let dayInt = Int(String(resultString.prefix(2))), dayInt > 29 {
                            resultString = String(resultString.dropLast()) // Удаляем последнюю цифру месяца
                            isValid = false
                        }
                    } else {
                        resultString += String(monthPart.prefix(1))
                        isValid = false
                    }
                }
            }
        }
        
        if cleanInput.count > 4 || (isDeleting && input.contains(".") && resultString.count == 5) {
            if resultString.count == 5 && !resultString.containsCharacter(".", at: resultString.index(resultString.startIndex, offsetBy: 4)) {
                resultString += "."
            }
        }
        
        // Обработка года
        if cleanInput.count > 4 {
            let yearStart = cleanInput.index(cleanInput.startIndex, offsetBy: 4)
            let yearPart = String(cleanInput[yearStart..<cleanInput.endIndex])
            
            if !yearPart.isEmpty {
                if yearPart.count >= 1 {
                    let yearFirstChar = yearPart.first!
                    if let yearFirstDigit = Int(String(yearFirstChar)), yearFirstDigit != 2 {
                        isValid = false
                        resultString = String(resultString.dropLast())
                    } else {
                        let limitedYear = String(yearPart.prefix(4))
                        resultString += limitedYear
                        
                        if limitedYear.count == 4, let yearInt = Int(limitedYear) {
                            if yearInt > 2100 {
                                isValid = false
                                resultString = String(resultString.dropLast())
                            } else if let minDate = minimumDate {
                                let calendar = Calendar.current
                                let minYear = calendar.component(.year, from: minDate)
                                let minMonth = calendar.component(.month, from: minDate)
                                let minDay = calendar.component(.day, from: minDate)
                                
                                let day = String(resultString.prefix(2))
                                let month = String(resultString[resultString.index(resultString.startIndex, offsetBy: 3)..<resultString.index(resultString.startIndex, offsetBy: 5)])
                                if let dayInt = Int(day), let monthInt = Int(month) {
                                    if yearInt < minYear ||
                                       (yearInt == minYear && monthInt < minMonth) ||
                                       (yearInt == minYear && monthInt == minMonth && dayInt < minDay) {
                                        isValid = false
                                        resultString = String(resultString.dropLast())
                                    }
                                }
                            }
                            
                            // Проверка високосного года для февраля
                            if resultString.count == 10 {
                                let day = Int(String(resultString.prefix(2))) ?? 0
                                let month = Int(String(resultString[resultString.index(resultString.startIndex, offsetBy: 3)..<resultString.index(resultString.startIndex, offsetBy: 5)])) ?? 0
                                if month == 2 {
                                    let isLeapYear = (yearInt % 4 == 0 && yearInt % 100 != 0) || (yearInt % 400 == 0)
                                    let maxDays = isLeapYear ? 29 : 28
                                    if day > maxDays {
                                        isValid = false
                                        hasValidationError = false
                                        if day == 29 && !isLeapYear {
                                            // Удаляем последнюю цифру года для 29 февраля в невисокосный год
                                            resultString = String(resultString.dropLast())
                                        }
                                    } else {
                                        hasValidationError = false
                                    }
                                } else {
                                    hasValidationError = false
                                }
                            }
                        }
                    }
                }
                
                if let opposite = oppositeDate, resultString.count == 10 {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd.MM.yyyy"
                    if let currentDate = formatter.date(from: resultString) {
                        if isStartDate && currentDate > opposite {
                            isValid = false
                            resultString = String(resultString.dropLast())
                        } else if !isStartDate && currentDate < opposite {
                            isValid = false
                            resultString = String(resultString.dropLast())
                        }
                    }
                }
            }
        }
        
        if isDeleting && resultString.count < input.count {
            resultString = input
        }
        
        return (resultString, isValid)
    }
    
    // MARK: - Helper Functions
    private func updateDateFromString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.isLenient = false
        
        if activeDateString.wrappedValue.count == 10, let newDate = formatter.date(from: activeDateString.wrappedValue) {
            date = newDate
            hasValidationError = false
        } else {
            date = nil
        }
    }
    
    func triggerShake() {
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeOffset = 0
        }
    }
}
