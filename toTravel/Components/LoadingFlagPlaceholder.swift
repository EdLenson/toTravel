//
//  LoadingFlagPlaceholder.swift
//  toTravel
//
//  Created by Ed on 4/5/25.
//

import SwiftUI

struct LoadingFlagPlaceholder: View {
    let width: CGFloat
    let height: CGFloat
    @State private var offset: CGFloat = -1.0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.secondary.opacity(0.3),
                        Theme.Colors.secondary.opacity(0.7),
                        Theme.Colors.secondary.opacity(0.3)
                    ]),
                    startPoint: .init(x: offset, y: 0.5),
                    endPoint: .init(x: offset + 1.0, y: 0.5)
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(4)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    offset = 1.0
                }
            }
    }
}
