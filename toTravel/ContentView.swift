//
//  ContentView.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var selectedPassport: Passport?
    @State private var selectedVisa: Visa?
    @State private var isSheetVisible: Bool = false
    
    private let sheetHeight: CGFloat = 0.7 // Фиксированная высота 60% для всех плашек
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedTab) {
                MyPassportsView(selectedPassport: $selectedPassport)
                    .tabItem {
                        Image(systemName: "person.text.rectangle")
                        Text("Мои паспорта")
                    }
                    .tag(0)
                    .onAppear {
                        print("Tab 0 (Passports) appeared")
                    }
                
                MyVisasView(selectedVisa: $selectedVisa)
                    .tabItem {
                        Image(systemName: "airplane")
                        Text("Мои визы")
                    }
                    .tag(1)
                    .onAppear {
                        print("Tab 1 (Visas) appeared")
                    }
                
                MyCountriesView()
                    .tabItem {
                        Image(systemName: "globe")
                        Text("Мои страны")
                    }
                    .tag(2)
                    .onAppear {
                        print("Tab 2 (Countries) appeared")
                    }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: TabViewFrameKey.self, value: proxy.frame(in: .global))
                }
            )
            .onPreferenceChange(TabViewFrameKey.self) { frame in
                print("TabView frame updated: \(frame)")
            }
            .toolbar(isSheetVisible ? .hidden : .visible, for: .tabBar)
            .customSheet(
                isPresented: Binding(
                    get: { selectedPassport != nil || selectedVisa != nil },
                    set: { if !$0 { selectedPassport = nil; selectedVisa = nil } }
                )
            ) {
                Group {
                    if let passport = selectedPassport {
                        PassportDetailView(
                            passport: passport,
                            isPresented: Binding(
                                get: { selectedPassport != nil },
                                set: { if !$0 { selectedPassport = nil } }
                            ),
                            isExpanded: .constant(false),
                            currentHeight: sheetHeight
                        )
                        .onAppear {
                            print("Passport sheet appeared: \(passport.customName)")
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSheetVisible = true
                            }
                        }
                    } else if let visa = selectedVisa {
                        VisaDetailView(
                            visa: visa,
                            isPresented: Binding(
                                get: { selectedVisa != nil },
                                set: { if !$0 { selectedVisa = nil } }
                            ),
                            isExpanded: .constant(false),
                            currentHeight: sheetHeight
                        )
                        .onAppear {
                            print("Visa sheet appeared: \(visa.customName)")
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSheetVisible = true
                            }
                        }
                    }
                }
            }
            .onChange(of: selectedPassport) { oldValue, newValue in
                print("selectedPassport changed: \(oldValue?.customName ?? "nil") -> \(newValue?.customName ?? "nil")")
            }
            .onChange(of: selectedVisa) { oldValue, newValue in
                print("selectedVisa changed: \(oldValue?.customName ?? "nil") -> \(newValue?.customName ?? "nil")")
            }
            .onChange(of: isSheetVisible) { oldValue, newValue in
                print("isSheetVisible changed: \(oldValue) -> \(newValue)")
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        selectedPassport = nil
                        selectedVisa = nil
                        print("Sheet closed, selectedPassport: \(selectedPassport?.customName ?? "nil"), selectedVisa: \(selectedVisa?.customName ?? "nil")")
                    }
                }
            }
        }
    }
}

struct TabViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Кастомный модификатор для плашки
struct CustomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> SheetContent
    
    private let sheetHeight: CGFloat = 0.7 // Фиксированная высота 60%
    @State private var sheetOffset: CGFloat = 0 // Управление позицией
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> SheetContent) {
        self._isPresented = isPresented
        self.content = content
        self._sheetOffset = State(initialValue: isPresented.wrappedValue ? 0 : 1000) // Начальное значение за экраном
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            GeometryReader { geometry in
                // Затемнение фона
                Color.black
                    .opacity(isPresented ? 0.5 : 0)
                    .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.bottom)
                    .offset(y: -geometry.safeAreaInsets.top)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: isPresented)
                    .ignoresSafeArea()
                    .zIndex(1) // Затемнение под плашкой
                
                // Плашка
                VStack {
                    Spacer() // Привязываем плашку к нижней части
                    self.content()
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * sheetHeight) // Фиксированная высота
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .offset(y: sheetOffset) // Управление движением
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    let translation = value.translation.height
                                    if translation > 50 {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isPresented = false
                                        }
                                    }
                                }
                        )
                        .opacity(1.0) // Явно фиксируем непрозрачность плашки
                }
                .ignoresSafeArea() // Поверх всего, включая tab bar
                .onChange(of: isPresented) { oldValue, newValue in
                    print("Sheet offset changing to: \(newValue ? 0 : geometry.size.height * sheetHeight)")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sheetOffset = newValue ? 0 : geometry.size.height * sheetHeight // Анимация снизу
                    }
                }
                .zIndex(2) // Плашка поверх затемнения
            }
        }
    }
}

extension View {
    func customSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(CustomSheetModifier(isPresented: isPresented, content: content))
    }
}

#Preview {
    ContentView()
}
