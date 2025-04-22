import SwiftUI
import SwiftData

// MARK: - VisaDetailView
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
    
    // MARK: - Computed Properties
    private var expirationWarning: String? {
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.startOfDay(for: visa.endDate)
        if let days = Calendar.current.dateComponents([.day], from: today, to: endDate).day {
            if days < 0 {
                return NSLocalizedString("Недействительна", comment: "Visa expiration status")
            } else if days == 0 {
                return NSLocalizedString("Истекает сегодня", comment: "Visa expiration status")
            } else if days < 90 {
                return String(format: NSLocalizedString("Истекает через %d дн.", comment: "Visa expiration warning with days"), days)
            }
        }
        return nil
    }
    
    private var passportName: String {
        visa.passport?.customName ?? NSLocalizedString("Неизвестный паспорт", comment: "Default passport name")
    }
    
    private var validityPeriodText: String {
        visa.validityPeriod < 0 ? NSLocalizedString("Неограниченно", comment: "Unlimited validity period") : String(format: NSLocalizedString("%d дн.", comment: "Validity period in days"), visa.validityPeriod)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(visa.customName.isEmpty ? NSLocalizedString("Без названия", comment: "Default visa name") : visa.customName)
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                
                HStack(spacing: 16) {
                    ActionButton(icon: "share", title: NSLocalizedString("Поделиться", comment: "Share action")) {
                        shareVisa()
                    }
                    .frame(width: 80, alignment: .center)
                    
                    ActionButton(icon: "edit", title: NSLocalizedString("Изменить", comment: "Edit action")) {
                        isShowingEditView = true
                    }
                    .frame(width: 80, alignment: .center)
                    
                    ActionButton(icon: "delete", title: NSLocalizedString("Удалить", comment: "Delete action")) {
                        deleteVisa()
                    }
                    .frame(width: 80, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Theme.Colors.surface(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 16) {
                InfoField(label: NSLocalizedString("Паспорт", comment: "Passport field label"), value: passportName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: NSLocalizedString("Страна выдачи", comment: "Issuing country field label"), value: countriesManager.getName(forCode: visa.issuingCountry))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: NSLocalizedString("Количество въездов", comment: "Entries count field label"), value: visa.entriesCount < 0 ? NSLocalizedString("Неограниченно", comment: "Unlimited entries") : String(visa.entriesCount))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: NSLocalizedString("Дата начала действия", comment: "Start date field label"), value: dateFormatter.string(from: visa.startDate))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: NSLocalizedString("Срок действия", comment: "Expiration date field label"), value: dateFormatter.string(from: visa.endDate))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let warning = expirationWarning {
                    InfoField(label: NSLocalizedString("Предупреждение", comment: "Expiration warning label"), value: warning, valueColor: Theme.Colors.expiring)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                InfoField(label: NSLocalizedString("Продолжительность пребывания", comment: "Validity period field label"), value: validityPeriodText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
        }
        .background(Theme.Colors.background(for: colorScheme))
        .sheet(isPresented: $isShowingEditView) {
            EditVisaView(isShowingEditVisaView: $isShowingEditView, visa: visa)
            .presentationDetents([.large])
        }
    }
    
    // MARK: - Helper Functions
    private func shareVisa() {
        let text = String(format: NSLocalizedString("Виза: %@\nПаспорт: %@\nСтрана выдачи: %@\nКоличество въездов: %@\nСрок действия: %@\nПродолжительность пребывания: %@\n%@", comment: "Share visa text format"),
                          visa.customName,
                          passportName,
                          countriesManager.getName(forCode: visa.issuingCountry),
                          visa.entriesCount < 0 ? NSLocalizedString("Неограниченно", comment: "Unlimited entries") : String(visa.entriesCount),
                          dateFormatter.string(from: visa.endDate),
                          validityPeriodText,
                          expirationWarning ?? "")
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(activityController, animated: true)
        }
    }
    
    private func deleteVisa() {
        NotificationManager.shared.removeNotifications(forVisa: visa)
        Task {
            do {
                if visa.passport != nil {
                    visa.passport = nil
                }
                modelContext.delete(visa)
                try modelContext.save()
                isPresented = false
            } catch {
                print(NSLocalizedString("Ошибка удаления визы: %@", comment: "Visa deletion error message"), error.localizedDescription)
            }
        }
    }
}
