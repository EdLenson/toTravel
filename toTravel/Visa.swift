//  Visas.swift
//  toTravel
//  Created by Ed on 3/21/25.

import Foundation
import SwiftData

@Model
class Visa {
    var customName: String
    @Relationship(deleteRule: .nullify) var passport: Passport?
    var issuingCountry: String
    var entriesCount: Int
    var issueDate: Date
    var startDate: Date
    var endDate: Date
    var validityPeriod: Int
    
    init(customName: String, passport: Passport? = nil, issuingCountry: String, entriesCount: Int, issueDate: Date, startDate: Date, endDate: Date, validityPeriod: Int) {
        self.customName = customName
        self.passport = passport
        self.issuingCountry = issuingCountry
        self.entriesCount = entriesCount
        self.issueDate = issueDate
        self.startDate = startDate
        self.endDate = endDate
        self.validityPeriod = validityPeriod
    }
}
