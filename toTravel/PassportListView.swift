//
//  PassportListView.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI
import SwiftData

struct PassportListView: View {
    let passports: [Passport]
    @Binding var selectedPassport: Passport?
    @Binding var isShowing: Bool
    
    var body: some View {
        Picker("Выберите паспорт", selection: $selectedPassport) {
            Text("Не выбрано").tag(nil as Passport?)
            ForEach(passports) { passport in
                Text(passport.customName).tag(passport as Passport?)
            }
        }
        .pickerStyle(.menu) // Простой выпадающий список
        .onChange(of: selectedPassport) { _ in
            isShowing = false // Закрываем после выбора
        }
    }
}
