import SwiftUI
import SwiftData

struct PassportDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let passport: Passport
    @Binding var isPresented: Bool
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
        
        if expiry < today {
            return "Недействителен"
        } else if expiry == today {
            return "Истекает сегодня"
        } else if monthsLeft < 6 {
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
            VStack(spacing: 0) {
                Text(passport.customName)
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                
                HStack(spacing: 16) {
                    ActionButton(icon: "share", title: "Поделиться") {
                        sharePassport()
                    }
                    .frame(width: 80, alignment: .center)
                    
                    ActionButton(icon: "edit", title: "Изменить") {
                        isShowingEditView = true
                    }
                    .frame(width: 80, alignment: .center)
                    
                    ActionButton(icon: "delete", title: "Удалить") {
                        showingDeleteConfirmation = true
                    }
                    .frame(width: 80, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Theme.Colors.background(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 16) {
                InfoField(label: "Тип паспорта", value: passport.type)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Страна выдачи", value: countriesManager.getName(forCode: passport.issuingCountry))
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoField(label: "Срок действия", value: expiryDateText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let expirationText = daysUntilExpiration {
                    InfoField(label: "Предупреждение", value: expirationText, valueColor: Theme.Colors.expiring)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                InfoField(label: "Визы в этом паспорте", value: passport.visas.isEmpty ? "Нет виз" : passport.visas.map { $0.customName.isEmpty ? "Без названия" : $0.customName }.joined(separator: ", "))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(Theme.Colors.surface(for: colorScheme))
            
            Spacer()
        }
        .sheet(isPresented: $isShowingEditView) {
            EditPassportView(isShowingEditPassportView: $isShowingEditView, passport: passport)
            .presentationDetents([.large])
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
