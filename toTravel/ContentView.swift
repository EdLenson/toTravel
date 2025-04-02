import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Environment and State
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab: Int = 0
    @State private var selectedPassportForDetail: Passport?
    @State private var selectedVisaForDetail: Visa?
    @State private var showPassportDetail: Bool = false
    @State private var showVisaDetail: Bool = false
    @State private var passportRotation: Double = 0
    @State private var planeOffset: CGSize = .zero
    @State private var planeOpacity: Double = 1.0
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Основной контент с сохранением состояния
                ZStack {
                    documentsView
                    countriesView
                }
                navigationBar
                modalOverlay
                passportDetailSheet
                visaDetailSheet
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .background(Theme.Colors.background(for: colorScheme))
            .accentColor(Theme.Colors.primary)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .background(Theme.Colors.background(for: colorScheme))
    }
    
    // MARK: - UI Components
    
    /// Экран "Мои документы"
    private var documentsView: some View {
        MyDocumentsView(
            selectedPassportForDetail: $selectedPassportForDetail,
            selectedVisaForDetail: $selectedVisaForDetail
        )
        .opacity(selectedTab == 0 ? 1.0 : 0.0)
        .zIndex(selectedTab == 0 ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(for: colorScheme))
        .onChange(of: selectedPassportForDetail) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                showPassportDetail = newValue != nil
            }
        }
        .onChange(of: selectedVisaForDetail) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                showVisaDetail = newValue != nil
            }
        }
    }
    
    /// Экран "Мои страны"
    private var countriesView: some View {
        MyCountriesView()
            .opacity(selectedTab == 1 ? 1.0 : 0.0)
            .zIndex(selectedTab == 1 ? 1 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background(for: colorScheme))
    }
    
    /// Навигационная панель с кнопками
    private var navigationBar: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .top, spacing: 16) {
                passportButton
                countriesButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    backgroundForScheme
                    selectionIndicator
                }
            )
            .clipShape(Capsule())
            .shadow(
                color: Theme.Tiles.shadowColor,
                radius: Theme.Tiles.shadowRadius,
                x: Theme.Tiles.shadowX,
                y: Theme.Tiles.shadowY
            )
            .padding(.bottom, 64)
        }
        .zIndex(2)
    }
    
    /// Кнопка для перехода к паспортам
    private var passportButton: some View {
        Button(action: {
            if selectedTab != 0 {
                selectedTab = 0
                withAnimation(.easeInOut(duration: 0.6)) {
                    passportRotation += 180
                }
            }
        }) {
            Image(selectedTab == 0 ? "passport_active" : "passport_inactive")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(selectedTab == 0 ? Theme.Colors.primary : Theme.Colors.secondary)
                .padding(8)
                .rotation3DEffect(
                    .degrees(passportRotation),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
    }
    
    /// Кнопка для перехода к странам
    private var countriesButton: some View {
            Button(action: {
                if selectedTab != 1 {
                    selectedTab = 1
                    withAnimation(.easeInOut(duration: 0.8)) {
                        planeOffset = CGSize(width: 44, height: -44)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        planeOffset = CGSize(width: -44, height: 44)
                        planeOpacity = 0.0
                        withAnimation(.easeInOut(duration: 0.2)) {
                            planeOffset = .zero
                            planeOpacity = 1.0
                        }
                    }
                }
            }) {
                Image(selectedTab == 1 ? "countries_active" : "countries_inactive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(selectedTab == 1 ? Theme.Colors.primary : Theme.Colors.secondary)
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .offset(planeOffset)
                    .opacity(planeOpacity)
                    .clipShape(Circle())
                    .clipped()
            }        }
    
    /// Фон навигационной панели в зависимости от темы
    private var backgroundForScheme: some View {
        colorScheme == .dark ? Theme.Colors.alternateBackground(for: colorScheme) : Theme.Colors.surface(for: colorScheme)
    }
    
    /// Индикатор выбранной вкладки с анимацией
    private var selectionIndicator: some View {
        Circle()
            .frame(width: 44, height: 44)
            .foregroundColor(Theme.Colors.primary.opacity(0.14))
            .offset(x: selectedTab == 0 ? -30 : 30, y: 0)
            .animation(.easeInOut(duration: 0.2), value: selectedTab) // Анимация только для индикатора
    }
    
    /// Полупрозрачный фон для модальных окон
    private var modalOverlay: some View {
        Group {
            if showPassportDetail || showVisaDetail {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPassportDetail = false
                            showVisaDetail = false
                        }
                    }
                    .zIndex(2.5)
                    .transition(.opacity)
            }
        }
    }
    
    /// Модальное окно для детального просмотра паспорта
    private var passportDetailSheet: some View {
        Group {
            if showPassportDetail, let passport = selectedPassportForDetail {
                CustomDetailSheet(isPresented: $showPassportDetail) {
                    PassportDetailView(passport: passport, isPresented: $showPassportDetail)
                }
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
    }
    
    /// Модальное окно для детального просмотра визы
    private var visaDetailSheet: some View {
        Group {
            if showVisaDetail, let visa = selectedVisaForDetail {
                CustomDetailSheet(isPresented: $showVisaDetail) {
                    VisaDetailView(visa: visa, isPresented: $showVisaDetail)
                }
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
    }
}
