import SwiftUI

struct CustomDetailSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var offset: CGFloat = 0
    @ViewBuilder let content: Content
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                content
                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.65)
                    .background(Theme.Colors.surface(for: colorScheme))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Theme.Tiles.passportCornerRadius, // 16
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: Theme.Tiles.passportCornerRadius // 16
                        )
                    )
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height >= 0 {
                                    offset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isPresented = false
                                        offset = geometry.size.height * 0.65
                                    }
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                }
                            }
                    )
                    .onTapGesture {}
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}
