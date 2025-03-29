//
//  CustomDateField.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI

extension String {
    func containsCharacter(_ character: Character, at index: Index) -> Bool {
        guard index < endIndex else { return false }
        return self[index] == character
    }
}

struct UnderlinedDateField: View {
    var title: String
    @Binding var date: Date?
    var dateString: Binding<String>? = nil
    var minimumDate: Date? = nil
    
    @State private var internalDateString: String = ""
    @State private var isEditing: Bool = false
    @State private var shakeOffset: CGFloat = 0
    
    private var activeDateString: Binding<String> {
        dateString ?? $internalDateString
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(isEditing ? Color.blue : .gray)
                    .offset(y: isEditing || !activeDateString.wrappedValue.isEmpty ? -25 : 0)
                    .scaleEffect(isEditing || !activeDateString.wrappedValue.isEmpty ? 0.8 : 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.2), value: isEditing || !activeDateString.wrappedValue.isEmpty)
                
                ZStack(alignment: .leading) {
                    if isEditing && activeDateString.wrappedValue.isEmpty {
                        Text("10.01.2020")
                            .foregroundColor(.gray)
                    }
                    
                    TextField("", text: activeDateString, onEditingChanged: { editing in
                        isEditing = editing
                        if !editing {
                            updateDateFromString()
                        }
                    })
                    .keyboardType(.numberPad)
                    .foregroundColor(.primary)
                    .onChange(of: activeDateString.wrappedValue) { newValue in
                        let (validatedString, isValid) = formatAndValidateDateString(newValue)
                        activeDateString.wrappedValue = validatedString
                        
                        if !isValid {
                            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                                shakeOffset = 10
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                shakeOffset = 0
                            }
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
                    .foregroundColor(isEditing ? Color.blue : Color.gray),
                alignment: .bottom
            )
            .offset(x: shakeOffset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .frame(height: 60)
        .onAppear {
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                activeDateString.wrappedValue = formatter.string(from: date)
            }
        }
        .onChange(of: date) { newDate in
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
    
    private func formatAndValidateDateString(_ input: String) -> (String, Bool) {
        print("Input: \(input)")
        
        // Удаляем все нецифровые символы, кроме точек (для обработки удаления)
        var cleanInput = input
        let isDeleting = input.count < activeDateString.wrappedValue.count
        
        // Если это не удаление, удаляем все нецифровые символы
        if !isDeleting {
            cleanInput = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        }
        
        // Ограничиваем максимальную длину
        if cleanInput.count > 8 && !isDeleting {
            cleanInput = String(cleanInput.prefix(8))
        }
        
        print("Formatted (no dots): \(cleanInput)")
        
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
        
        // Добавляем точку после дня, если нужно
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
                    } else {
                        resultString += String(monthPart.prefix(1))
                        isValid = false
                    }
                }
            }
        }
        
        // Добавляем точку после месяца, если нужно
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
                // Проверяем первую цифру года (должна быть 2)
                if yearPart.count >= 1 {
                    let yearFirstChar = yearPart.first!
                    if let yearFirstDigit = Int(String(yearFirstChar)), yearFirstDigit != 2 {
                        isValid = false
                        resultString = String(resultString.dropLast()) // Обрезаем, если год не начинается с 2
                    } else {
                        // Ограничиваем год 4 цифрами
                        let limitedYear = String(yearPart.prefix(4))
                        resultString += limitedYear
                        
                        // Проверяем валидность года
                        if limitedYear.count == 4, let yearInt = Int(limitedYear) {
                            if yearInt > 2100 {
                                isValid = false
                                resultString = String(resultString.dropLast()) // Обрезаем, если год > 2100
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
                                        resultString = String(resultString.dropLast()) // Обрезаем, если год меньше минимального
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Если это удаление и результат короче исходного, возвращаем как есть
        if isDeleting && resultString.count < input.count {
            resultString = input
        }
        
        print("After formatting: \(resultString)")
        print("Final result: \(resultString), isValid: \(isValid)")
        return (resultString, isValid)
    }
    
    private func updateDateFromString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.isLenient = false
        
        if activeDateString.wrappedValue.count == 10, let newDate = formatter.date(from: activeDateString.wrappedValue) {
            date = newDate
        } else {
            date = nil
        }
    }
}
