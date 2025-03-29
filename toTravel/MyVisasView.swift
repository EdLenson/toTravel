//
//  MyVisasView.swift
//  toTravel
//
//  Created by Ed on 3/23/25.
//

import SwiftUI
import SwiftData

struct MyVisasView: View {
    @Environment(\.modelContext) private var modelContext
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
    
    init(selectedVisa: Binding<Visa?>) {
        self._selectedVisa = selectedVisa
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if validVisas.isEmpty {
                        Text("Нет виз")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    } else {
                        ForEach(validVisas) { visa in
                            Button(action: {
                                selectedVisa = visa
                                print("Tapped visa: \(visa.customName)")
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
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, validVisas.isEmpty ? 0 : 16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Мои визы")
            .padding(.top, 16)
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $isShowingAddVisaView) {
                AddVisaView(isShowingAddVisaView: $isShowingAddVisaView)
            }
        }
    }
}

#Preview {
    MyVisasView(selectedVisa: .constant(nil))
}
