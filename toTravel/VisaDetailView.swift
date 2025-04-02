import SwiftUI
import SwiftData

struct VisaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let visa: Visa
    @Binding var isPresented: Bool
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    @State private var isShowingEditView: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    private var expirationWarning: String? {
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.startOfDay(for: visa.endDate)
        if let days = Calendar.current.dateComponents([.day], from: today, to: endDate).day {
            if days < 0 {
                return "Недействительна"
            } else if days == 0 {
                return "Истекает сегодня"
            } else if days < 90 {
                return "Истекает через \(days) дн."
            }
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
            VStack(spacing: 0) {
                Text(visa.customName.isEmpty ? "Нет названия" : visa.customName)
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                
                HStack(spacing: 16) {
                    ActionButton(icon: "share", title: "Поделиться") {
                        shareVisa()
                    }
                    .frame(width: 80, alignment: .center)
                    
                    ActionButton(icon: "edit", title: "Изменить") {
                        isShowingEditView = true
                    }
                    .frame(width: 80, alignment: .center)
                    
                    ActionButton(icon: "delete", title: "Удалить") {
                        deleteVisa()
                    }
                    .frame(width: 80, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Theme.Colors.background(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 16) {
                InfoField(label: "Паспорт", value: passportName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Страна выдачи", value: countriesManager.getName(forCode: visa.issuingCountry))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Количество въездов", value: visa.entriesCount < 0 ? "Неограниченно" : String(visa.entriesCount))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Срок действия", value: dateFormatter.string(from: visa.endDate))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let warning = expirationWarning {
                    InfoField(label: "Предупреждение", value: warning, valueColor: Theme.Colors.expiring)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                InfoField(label: "Продолжительность пребывания", value: validityPeriodText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(Theme.Colors.surface(for: colorScheme))
            
            Spacer()
        }
        .sheet(isPresented: $isShowingEditView) {
            EditVisaView(isShowingEditVisaView: $isShowingEditView, visa: visa)
            .presentationDetents([.large])
        }
    }
    
    private func shareVisa() {
        let text = """
        Виза: \(visa.customName)
        Паспорт: \(passportName)
        Страна выдачи: \(countriesManager.getName(forCode: visa.issuingCountry))
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
