//  PassportDetailView.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI
import SwiftData

struct PassportDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let passport: Passport
    @Binding var isPresented: Bool
    @Binding var isExpanded: Bool
    let currentHeight: CGFloat
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var isShowingEditView: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    private var expiryDateText: String {
        passport.expiryDate >= Date.distantFuture ? "Бессрочный" : dateFormatter.string(from: passport.expiryDate)
    }
    
    private var daysUntilExpiration: String? {
        let today = Calendar.current.startOfDay(for: Date())
        let expiry = Calendar.current.startOfDay(for: passport.expiryDate)
        let components = Calendar.current.dateComponents([.month, .day], from: today, to: expiry)
        
        let monthsLeft = components.month ?? 0
        let daysLeft = components.day ?? 0
        
        if passport.expiryDate >= Date.distantFuture { return nil }
        
        if monthsLeft < 6 && monthsLeft >= 0 {
            if monthsLeft > 1 {
                return "Истекает через \(monthsLeft) мес. \(daysLeft) дн."
            } else if monthsLeft == 1 {
                let totalDays = Calendar.current.dateComponents([.day], from: today, to: passport.expiryDate).day ?? 0
                return "Истекает через 1 мес. \(totalDays - 30) дн."
            } else {
                return "Истекает через \(daysLeft) дн."
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(passport.customName)
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.leading, 16)
                .padding(.bottom, 32)
            
            HStack(spacing: 16) {
                ActionButton(icon: "square.and.arrow.up", title: "Поделиться") {
                    sharePassport()
                }
                ActionButton(icon: "pencil", title: "Редактировать") {
                    isShowingEditView = true
                }
                ActionButton(icon: "trash", title: "Удалить", color: .red) {
                    showingDeleteConfirmation = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 16) {
                InfoField(label: "Тип паспорта", value: passport.type)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Страна выдачи", value: countriesManager.getName(forCode: passport.issuingCountry))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Срок действия", value: expiryDateText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let expirationText = daysUntilExpiration {
                    InfoField(label: "Предупреждение", value: expirationText, valueColor: .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                InfoField(label: "Визы в этом паспорте", value: passport.visas.isEmpty ? "Нет виз" : passport.visas.map { $0.customName.isEmpty ? "Без названия" : $0.customName }.joined(separator: ", "))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $isShowingEditView) {
            EditPassportView(isShowingEditPassportView: $isShowingEditView, passport: passport)
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Удалить паспорт?"),
                message: Text(passport.visas.isEmpty ? "Вы уверены?" : "Будут удалены связанные визы"),
                primaryButton: .destructive(Text("Удалить")) {
                    deletePassport()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func sharePassport() {
        let text = """
        Паспорт: \(passport.customName)
        Тип паспорта: \(passport.type)
        Страна выдачи: \(countriesManager.getName(forCode: passport.issuingCountry))
        Срок действия: \(expiryDateText)
        """
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityController, animated: true)
    }
    
    private func deletePassport() {
        modelContext.delete(passport)
        try? modelContext.save()
        isPresented = false
    }
}

#Preview {
    PassportDetailView(
        passport: Passport(customName: "Test", issuingCountry: "RU", expiryDate: Date(), type: "Заграничный"),
        isPresented: .constant(true),
        isExpanded: .constant(false),
        currentHeight: 0.7
    )
}
