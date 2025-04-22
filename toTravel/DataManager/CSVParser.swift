//
//  CSVParser.swift
//  toTravel
//
//  Created by Ed on 3/27/25.
//
import Foundation

class CSVParser {
    static func fetchCountryAccessData() async throws -> [String: [CountryAccess]] {
        let url = URL(string: "https://raw.githubusercontent.com/ilyankou/passport-index-dataset/master/passport-index-tidy-iso2.csv")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        var countryAccessDict: [String: [CountryAccess]] = [:]
        let rows = csvString.components(separatedBy: "\n").dropFirst() // Пропускаем заголовок
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 3 else { continue }
            
            let passport = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let destination = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let requirement = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
            
            let access = CountryAccess(destination: destination, requirement: requirement)
            if countryAccessDict[passport] == nil {
                countryAccessDict[passport] = []
            }
            countryAccessDict[passport]?.append(access)
        }
        return countryAccessDict
    }
}
