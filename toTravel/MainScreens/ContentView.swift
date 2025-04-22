import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct UpdateInfo: Codable {
    let version: String
    let appStoreUrl: String
}

struct ContentView: View {
    // MARK: - Environment and State
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab: Int = 0
    @State private var selectedPassportForDetail: Passport?
    @State private var selectedVisaForDetail: Visa?
    @State private var showPassportDetail: Bool = false
    @State private var showVisaDetail: Bool = false
    @State private var showUpdateSheet: Bool = false
    @State private var appStoreUrl: String = ""
    @State private var passportRotation: Double = 0
    @State private var planeOffset: CGSize = .zero
    @State private var planeOpacity: Double = 1.0
    
    init() {
        requestNotificationPermission()
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    documentsView
                    countriesView
                }
                navigationBar
                modalOverlay
                passportDetailSheet
                visaDetailSheet
                updateSheet
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .background(Theme.Colors.background(for: colorScheme))
            .accentColor(Theme.Colors.primary(for: colorScheme))
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .background(Theme.Colors.background(for: colorScheme))
        .onAppear {
            checkForUpdateAndShowIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if showUpdateSheet {
                switch newPhase {
                case .background, .inactive:
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showUpdateSheet = false
                    }
                default:
                    break
                }
            }
        }
        .onChange(of: showUpdateSheet) { _, newValue in
            if !newValue {
                saveLastShownTime() // Сохраняем время при любом закрытии
            }
        }
    }
    
    // MARK: - UI Components
    
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
    
    private var countriesView: some View {
        MyCountriesView()
            .opacity(selectedTab == 1 ? 1.0 : 0.0)
            .zIndex(selectedTab == 1 ? 1 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background(for: colorScheme))
    }
    
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
    
    private var passportButton: some View {
        Button(action: {
            if selectedTab != 0 {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
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
                .foregroundColor(selectedTab == 0 ? Theme.Colors.background : Theme.Colors.background)
                .padding(8)
                .rotation3DEffect(
                    .degrees(passportRotation),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var countriesButton: some View {
        Button(action: {
            if selectedTab != 1 {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                selectedTab = 1
                withAnimation(.easeInOut(duration: 0.8)) {
                    planeOffset = CGSize(width: 44, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    planeOffset = CGSize(width: -44, height: 0)
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
                .foregroundColor(selectedTab == 0 ? Theme.Colors.background : Theme.Colors.background)
                .padding(8)
                .frame(width: 44, height: 44)
                .offset(planeOffset)
                .opacity(planeOpacity)
                .clipShape(Circle())
                .clipped()
        }
        .buttonStyle(DefaultButtonStyle())
    }
    
    private var backgroundForScheme: some View {
        Theme.Colors.primary(for: colorScheme)
    }
    
    private var selectionIndicator: some View {
        Circle()
            .frame(width: 44, height: 44)
            .foregroundColor(Theme.Colors.background(for: colorScheme).opacity(0.14))
            .offset(x: selectedTab == 0 ? -30 : 30, y: 0)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    private var modalOverlay: some View {
        Group {
            if showPassportDetail || showVisaDetail || showUpdateSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPassportDetail = false
                            showVisaDetail = false
                            showUpdateSheet = false
                        }
                    }
                    .zIndex(2.5)
                    .transition(.opacity)
            }
        }
    }
    
    private var passportDetailSheet: some View {
        Group {
            if showPassportDetail, let passport = selectedPassportForDetail {
                CustomDetailSheet(
                    isPresented: $showPassportDetail,
                    heightFraction: 0.50
                ) {
                    PassportDetailView(passport: passport, isPresented: $showPassportDetail)
                }
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
    }
    
    private var visaDetailSheet: some View {
        Group {
            if showVisaDetail, let visa = selectedVisaForDetail {
                CustomDetailSheet(
                    isPresented: $showVisaDetail,
                    heightFraction: 0.70
                ) {
                    VisaDetailView(visa: visa, isPresented: $showVisaDetail)
                }
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
    }
    
    private var updateSheet: some View {
        Group {
            if showUpdateSheet {
                UpdateSheet(
                    isPresented: $showUpdateSheet,
                    appStoreUrl: appStoreUrl,
                    onUpdateTapped: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showUpdateSheet = false
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
    }
    
    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Разрешение на уведомления получено")
            } else {
                print("Разрешение отклонено: \(error?.localizedDescription ?? "нет ошибки")")
            }
        }
    }
    
    // MARK: - Update Check
    private func checkForUpdate(completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: "https://totravelapp.ru/appupdateversions/needupdate.json") else {
            print("Неверный URL")
            completion(nil, nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Ошибка загрузки: \(String(describing: error))")
                completion(nil, nil)
                return
            }
            
            do {
                let updateInfo = try JSONDecoder().decode(UpdateInfo.self, from: data)
                completion(updateInfo.version, updateInfo.appStoreUrl)
            } catch {
                print("Ошибка декодирования: \(error)")
                completion(nil, nil)
            }
        }.resume()
    }
    
    // MARK: - Update Logic
    private func checkForUpdateAndShowIfNeeded() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("Не удалось получить текущую версию приложения")
            return
        }
        
        let lastShownTime = UserDefaults.standard.double(forKey: "lastUpdateSheetShownTime")
        let currentTime = Date().timeIntervalSince1970
        let hoursSinceLastShown = (currentTime - lastShownTime) / 3600
        
        if hoursSinceLastShown < 0.01 {
            return
        }
        
        checkForUpdate { serverVersion, url in
            guard let serverVersion = serverVersion, let url = url else {
                return
            }
            
            DispatchQueue.main.async {
                if currentVersion.compare(serverVersion, options: .numeric) == .orderedAscending {
                    self.appStoreUrl = url
                    self.showUpdateSheet = true
                }
            }
        }
    }
    
    private func saveLastShownTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdateSheetShownTime")
    }
}

#Preview {
    ContentView()
}
