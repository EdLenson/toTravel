import Foundation
import SwiftUI

class CountriesViewModel: ObservableObject {
    @Published var selectedCategory: MyCountriesView.VisaCategory = .visaFree
    @Published private var visaCategories: [MyCountriesView.VisaCategory: [CountryAccess]] = [:]
    private let countriesManager: CountriesManager
    private var visas: [Visa] = [] // Список виз
    private var currentPassport: Passport? // Текущий паспорт
    
    init(countriesManager: CountriesManager) {
        self.countriesManager = countriesManager
    }
    
    func updateCategories(for passport: Passport?, visas: [Visa] = []) {
        self.currentPassport = passport
        self.visas = visas
        guard let passport = passport else {
            visaCategories = [:]
            return
        }
        let issuingCountry = passport.issuingCountry.uppercased()
        let accessData = countriesManager.getCountryAccessData()[issuingCountry] ?? []
        
        visaCategories[.visaFree] = accessData.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa free" ||
            (Int($0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && $0.requirement != "-1")
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) }
        
        visaCategories[.visaOnArrival] = accessData.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa on arrival"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) }
        
        visaCategories[.eVisa] = accessData.filter {
            let req = $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines)
            return req == "e-visa" || req == "eta"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) }
        
        visaCategories[.visaRequired] = accessData.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "visa required"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) }
        
        visaCategories[.noAdmission] = accessData.filter {
            $0.requirement.trimmingCharacters(in: .whitespacesAndNewlines) == "no admission"
        }.sorted { countriesManager.getName(forCode: $0.destination) < countriesManager.getName(forCode: $1.destination) }
    }
    
    func countries(for category: MyCountriesView.VisaCategory) -> [CountryAccess] {
        visaCategories[category] ?? []
    }
    
    func count(for category: MyCountriesView.VisaCategory) -> Int {
        visaCategories[category]?.count ?? 0
    }
    
    // Новый метод для получения визы для страны
    func getVisa(forCountryCode code: String) -> Visa? {
        return countriesManager.getValidVisa(forCountryCode: code, passport: currentPassport, visas: visas)
    }
}
