//
//  VisaDetailView.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI
import SwiftData

struct VisaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let visa: Visa
    @Binding var isPresented: Bool
    @Binding var isExpanded: Bool
    let currentHeight: CGFloat
    
    @State private var isShowingEditView: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    private var expirationWarning: String? {
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.startOfDay(for: visa.endDate)
        if let days = Calendar.current.dateComponents([.day], from: today, to: endDate).day, days < 90 && days > 0 {
            return "Истекает через \(days) дн."
        }
        return nil
    }
    
    private var passportName: String {
        visa.passport?.customName ?? "Неизвестный паспорт"
    }
    
    private var validityPeriodText: String {
        visa.validityPeriod < 0 ? "Неограниченно" : "\(visa.validityPeriod) дн."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Название документа
            Text(visa.customName.isEmpty ? "Нет названия" : visa.customName)
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.leading, 16)
                .padding(.bottom, 32)
            
            // Кнопки
            HStack(spacing: 16) {
                ActionButton(icon: "square.and.arrow.up", title: "Поделиться") {
                    shareVisa()
                }
                ActionButton(icon: "pencil", title: "Редактировать") {
                    isShowingEditView = true
                }
                ActionButton(icon: "trash", title: "Удалить", color: .red) {
                    deleteVisa()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Информация
            VStack(alignment: .leading, spacing: 16) {
                InfoField(label: "Паспорт", value: passportName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Страна выдачи", value: visa.issuingCountry.isEmpty ? "Не указана" : visa.issuingCountry)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Количество въездов", value: visa.entriesCount < 0 ? "Неограниченно" : String(visa.entriesCount))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Срок действия", value: dateFormatter.string(from: visa.endDate))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let warning = expirationWarning {
                    InfoField(label: "Предупреждение", value: warning, valueColor: .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                InfoField(label: "Продолжительность пребывания", value: validityPeriodText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $isShowingEditView) {
            EditVisaView(isShowingEditVisaView: $isShowingEditView, visa: visa)
        }
    }
    
    private func shareVisa() {
        let text = """
        Виза: \(visa.customName)
        Паспорт: \(passportName)
        Страна выдачи: \(visa.issuingCountry)
        Количество въездов: \(visa.entriesCount < 0 ? "Неограниченно" : String(visa.entriesCount))
        Срок действия: \(dateFormatter.string(from: visa.endDate))
        Продолжительность пребывания: \(validityPeriodText)
        \(expirationWarning ?? "")
        """
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityController, animated: true)
    }
    
    private func deleteVisa() {
        Task {
            do {
                guard let passport = visa.passport else {
                    modelContext.delete(visa)
                    try modelContext.save()
                    isPresented = false
                    return
                }
                
                visa.passport = nil
                modelContext.delete(visa)
                try modelContext.save()
                isPresented = false
            } catch {
                print("Ошибка удаления визы: \(error.localizedDescription)")
            }
        }
    }
}
