import SwiftUI
import SwiftData

struct MyVisasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var visas: [Visa]
    @Binding var selectedVisa: Visa?
    @State private var isShowingAddVisaView: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    private var validVisas: [Visa] {
        visas.filter { $0.passport != nil }
    }
    
    // Сортированные визы
    private var sortedVisas: [Visa] {
        validVisas.sorted { visa1, visa2 in
            let today = Calendar.current.startOfDay(for: Date())
            let end1 = Calendar.current.startOfDay(for: visa1.endDate)
            let end2 = Calendar.current.startOfDay(for: visa2.endDate)
            
            let monthsLeft1 = Calendar.current.dateComponents([.month], from: today, to: end1).month ?? 0
            let monthsLeft2 = Calendar.current.dateComponents([.month], from: today, to: end2).month ?? 0
            
            let isExpiringSoon1 = monthsLeft1 < 3 || end1 <= today // < 3 месяцев, истекает сегодня или просрочена
            let isExpiringSoon2 = monthsLeft2 < 3 || end2 <= today
            
            // Визы с истекающим сроком выше
            if isExpiringSoon1 != isExpiringSoon2 {
                return isExpiringSoon1 && !isExpiringSoon2
            }
            // Если обе истекают или обе нормальные, сортируем по дате окончания
            return end1 < end2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: Theme.Tiles.listSpacing) {
                        Spacer(minLength: 70) // Отступ под плашку
                        
                        if validVisas.isEmpty {
                            Text("Нет виз")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        } else {
                            ForEach(sortedVisas) { visa in
                                Button(action: {
                                    selectedVisa = visa
                                }) {
                                    VisaTileView(visa: visa, dateFormatter: dateFormatter)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        Button(action: {
                            isShowingAddVisaView = true
                        }) {
                            Text("Добавить визу")
                                .font(Theme.Fonts.button)
                                .foregroundColor(Theme.Colors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.surface(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Tiles.cornerRadius))
                        }
                        .padding(.top, validVisas.isEmpty ? 0 : Theme.Tiles.spacing)
                    }
                    .padding(.horizontal, Theme.Tiles.listEdgePadding)
                    .padding(.bottom, Theme.Tiles.verticalPadding)
                }
                .background(Theme.Colors.background(for: colorScheme))
                
                VStack {
                    Text("Мои визы")
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
            .sheet(isPresented: $isShowingAddVisaView) {
                AddVisaView(isShowingAddVisaView: $isShowingAddVisaView)
            }
        }
    }
}

#Preview {
    MyVisasView(selectedVisa: .constant(nil))
}
