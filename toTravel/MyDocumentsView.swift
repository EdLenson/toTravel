import SwiftUI
import SwiftData

struct MyPassportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var passports: [Passport]
    @Binding var selectedPassport: Passport?
    @State private var isShowingAddPassportView: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    // Сортированные паспорта
    private var sortedPassports: [Passport] {
        passports.sorted { passport1, passport2 in
            let today = Calendar.current.startOfDay(for: Date())
            let expiry1 = Calendar.current.startOfDay(for: passport1.expiryDate)
            let expiry2 = Calendar.current.startOfDay(for: passport2.expiryDate)
            
            let monthsLeft1 = Calendar.current.dateComponents([.month], from: today, to: expiry1).month ?? 0
            let monthsLeft2 = Calendar.current.dateComponents([.month], from: today, to: expiry2).month ?? 0
            
            let isExpiringSoon1 = monthsLeft1 < 6 || expiry1 < today
            let isExpiringSoon2 = monthsLeft2 < 6 || expiry2 < today
            
            // Паспорта с истекающим сроком (< 6 месяцев или просроченные) выше
            if isExpiringSoon1 != isExpiringSoon2 {
                return isExpiringSoon1 && !isExpiringSoon2
            }
            // Если оба истекают или оба нормальные, сортируем по дате истечения
            return expiry1 < expiry2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: Theme.Tiles.listSpacing) {
                        Spacer(minLength: 70) // Отступ под плашку
                        
                        if passports.isEmpty {
                            Text("Нет паспортов")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        } else {
                            ForEach(sortedPassports) { passport in
                                Button(action: {
                                    selectedPassport = passport
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
                                .font(Theme.Fonts.button)
                                .foregroundColor(Theme.Colors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.surface(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Tiles.cornerRadius))
                        }
                        .padding(.top, passports.isEmpty ? 0 : Theme.Tiles.spacing)
                    }
                    .padding(.horizontal, Theme.Tiles.listEdgePadding)
                    .padding(.bottom, Theme.Tiles.verticalPadding)
                }
                .background(Theme.Colors.background(for: colorScheme))
                
                VStack {
                    Text("Мои паспорта")
                        .font(Theme.Fonts.header)
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                }
                .background(Theme.Colors.background(for: colorScheme))
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .top, content: {
                Color.clear.frame(height: 0)
            })
            .sheet(isPresented: $isShowingAddPassportView) {
                AddPassportView(isShowingAddPassportView: $isShowingAddPassportView)
            }
        }
    }
}

#Preview {
    MyPassportsView(selectedPassport: .constant(nil))
}
