//
//  Passport.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//
import Foundation
import SwiftData

@Model
class Passport {
    var customName: String
    var issuingCountry: String
    var expiryDate: Date
    var type: String
    @Relationship(deleteRule: .nullify, inverse: \Visa.passport) var visas: [Visa] = []
    
    init(customName: String, issuingCountry: String, expiryDate: Date, type: String) {
        self.customName = customName
        self.issuingCountry = issuingCountry
        self.expiryDate = expiryDate
        self.type = type
    }
}
