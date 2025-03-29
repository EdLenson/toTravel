//
//  MyPassportsView.swift
//  toTravel
//
//  Created by Ed on 3/23/25.
//

import SwiftUI
import SwiftData

struct MyPassportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var passports: [Passport]
    @Binding var selectedPassport: Passport?
    @State private var isShowingAddPassportView: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    init(selectedPassport: Binding<Passport?>) {
        self._selectedPassport = selectedPassport
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if passports.isEmpty {
                        Text("Нет паспортов")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    } else {
                        ForEach(passports) { passport in
                            Button(action: {
                                selectedPassport = passport
                                print("Tapped passport: \(passport.customName)")
                            }) {
                                PassportTileView(passport: passport, dateFormatter: dateFormatter)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Button(action: {
                        isShowingAddPassportView = true
                    }) {
                        Text("Добавить паспорт")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, passports.isEmpty ? 0 : 16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Мои паспорта")
            .padding(.top, 16)
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $isShowingAddPassportView) {
                AddPassportView(isShowingAddPassportView: $isShowingAddPassportView)
            }
        }
    }
}

struct PassportTileView: View {
    let passport: Passport
    let dateFormatter: DateFormatter
    
    private var expiryText: String {
        passport.expiryDate >= Date.distantFuture ? "Бессрочный" : "до \(dateFormatter.string(from: passport.expiryDate))"
    }
    
    private var isExpiringSoon: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let expiry = Calendar.current.startOfDay(for: passport.expiryDate)
        let components = Calendar.current.dateComponents([.month], from: today, to: expiry)
        
        if passport.expiryDate >= Date.distantFuture { return false }
        let monthsLeft = components.month ?? 0
        return monthsLeft < 6 && expiry > today
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "person.text.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(passport.customName.isEmpty ? "Без названия" : passport.customName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(expiryText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 0)
        .frame(width: 361, height: 80, alignment: .leading)
        .background(.white)
        .cornerRadius(8)
        .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.18).opacity(0.07), radius: 7.5, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(
                    isExpiringSoon ?
                        Color(red: 1, green: 0.4, blue: 0.38) :
                        Color(red: 0.94, green: 0.94, blue: 0.94),
                    lineWidth: 1
                )
        )
    }
}
