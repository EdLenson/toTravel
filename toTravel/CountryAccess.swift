//
//  CountryAccess.swift
//  toTravel
//
//  Created by Ed on 3/28/25.
//
struct CountryAccess: Codable, Equatable {
    let destination: String
    let requirement: String
    
    static func ==(lhs: CountryAccess, rhs: CountryAccess) -> Bool {
        return lhs.destination == rhs.destination && lhs.requirement == rhs.requirement
    }
}
