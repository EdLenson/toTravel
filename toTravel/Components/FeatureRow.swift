struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var isAnimated: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @State private var animate = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Theme.Colors.primary(for: colorScheme))
                .scaleEffect(animate ? 1.15 : 1.0)
                .animation(.easeOut(duration: 0.2), value: animate)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondary(for: colorScheme))
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.Colors.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if isAnimated {
                startHeartbeat()
            }
        }
    }

    private func startHeartbeat() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    animate = true
                }
                // Вибрация!
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        animate = false
                    }
                }
            }
        }
    }
}