//
//  VisaTypesLib.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import Foundation

struct VisaTypesLib {
    static let visaTypesByCountry: [String: [String]] = [
        "Соединенные Штаты Америки": ["B1/B2", "F1/M1", "H, L, O, P, Q, R", "J", "C/D"],
        "Германия": ["Краткосрочная типа С", "Долгосрочная типа D"],
        "Франция": ["Краткосрочная типа С", "Долгосрочная типа D"],
        "Италия": ["Краткосрочная типа С", "Долгосрочная типа D"],
        "Испания": ["Краткосрочная типа С", "Долгосрочная типа D"],
        "Китай": ["L", "F", "Z", "X", "M", "Q", "S", "G"],
        "Япония": ["Краткосрочная", "Рабочая", "Студенческая", "Дипломатическая"],
        "Канада": ["Туристическая", "Студенческая", "Рабочая", "Транзитная"],
        "Великобритания": ["Standard Visitor", "Student", "Work", "Transit"],
        "Австралия": ["Туристическая", "Студенческая", "Рабочая", "Транзитная"],
        // Добавьте остальные страны и их типы виз...
    ]
}
