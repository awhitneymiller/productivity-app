import SwiftUI

private enum WrappedPalette {
    // Soft, cool-toned pastels
    static let background = Color(red: 0.97, green: 0.97, blue: 0.99)      // near-white lavender
    static let surface    = Color(red: 0.96, green: 0.97, blue: 1.00)      // airy pale blue
    static let ink        = Color(red: 0.28, green: 0.27, blue: 0.38)      // soft charcoal-purple
    static let inkMuted   = Color(red: 0.45, green: 0.44, blue: 0.56)

    static let lavender   = Color(red: 0.85, green: 0.82, blue: 0.97)
    static let periwinkle = Color(red: 0.78, green: 0.84, blue: 0.99)
    static let paleBlue   = Color(red: 0.78, green: 0.93, blue: 0.99)

    static let accent     = Color(red: 0.72, green: 0.64, blue: 0.95)      // gentle purple accent
    static let accent2    = Color(red: 0.66, green: 0.78, blue: 0.96)      // periwinkle accent
    static let highlight  = Color(red: 0.98, green: 0.93, blue: 0.70)      // muted yellow
}

struct WrappedView: View {
    struct WrappedCardPage: Identifiable {
        let id = UUID()
        let title: String
        let bigValue: String
        let subtitle: String
        let detail: String
        let systemImage: String
        let accent: Color
    }

    private let pages: [WrappedCardPage] = [
        .init(
            title: "Today, you finished",
            bigValue: "12 tasks",
            subtitle: "Nice follow-through",
            detail: "Placeholder: includes checked tasks + quick wins",
            systemImage: "checkmark.circle.fill",
            accent: WrappedPalette.accent
        ),
        .init(
            title: "You stayed focused for",
            bigValue: "2h 40m",
            subtitle: "Deep work time",
            detail: "Placeholder: total focused minutes across sessions",
            systemImage: "timer",
            accent: WrappedPalette.accent2
        ),
        .init(
            title: "Your busiest block was",
            bigValue: "3–5 PM",
            subtitle: "Peak productivity window",
            detail: "Placeholder: based on when you completed most items",
            systemImage: "chart.bar.fill",
            accent: WrappedPalette.periwinkle
        ),
        .init(
            title: "You protected",
            bigValue: "4 breaks",
            subtitle: "Good pacing",
            detail: "Placeholder: short rests + transition time",
            systemImage: "leaf.fill",
            accent: WrappedPalette.lavender
        ),
        .init(
            title: "Tomorrow is looking like",
            bigValue: "3 priorities",
            subtitle: "Start simple",
            detail: "Placeholder: top items pulled from your plan",
            systemImage: "sparkles",
            accent: WrappedPalette.highlight
        )
    ]

    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            WrappedPalette.background
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    WrappedCard(page: page, index: index)
                        .tag(index)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private struct WrappedCard: View {
        let page: WrappedCardPage
        let index: Int

        var body: some View {
            GeometryReader { proxy in
                let size = proxy.size

                ZStack {
                    abstractLayer(size: size)

                    VStack(spacing: 18) {
                        Spacer(minLength: 0)

                        // Top label
                        Text(page.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(WrappedPalette.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)

                        // Big stat
                        Text(page.bigValue)
                            .font(.system(size: min(size.width * 0.18, 86), weight: .heavy, design: .rounded))
                            .foregroundStyle(page.accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Subtitle
                        Text(page.subtitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(WrappedPalette.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)

                        // Detail (kept small + airy)
                        Text(page.detail)
                            .font(.footnote)
                            .foregroundStyle(WrappedPalette.inkMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                            .padding(.top, 2)

                        Spacer(minLength: 0)

                        // Bottom pill
                        HStack(spacing: 10) {
                            Image(systemName: page.systemImage)
                                .font(.headline)
                                .foregroundStyle(page.accent)

                            Text("End of Day • Placeholder Stats")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(WrappedPalette.ink)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule(style: .continuous)
                                .fill(WrappedPalette.surface)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(page.accent.opacity(0.22), lineWidth: 1)
                                )
                                .shadow(color: page.accent.opacity(0.12), radius: 18, x: 0, y: 10)
                        )
                        .padding(.bottom, 26)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 8)
                }
            }
        }

        private func abstractLayer(size: CGSize) -> some View {
            let width = size.width
            let height = size.height

            // Rotate through a few soft tints per card
            let tintA: Color = page.accent.opacity(0.55)
            let tintB: Color = WrappedPalette.paleBlue.opacity(0.85)
            let tintC: Color = WrappedPalette.lavender.opacity(0.85)
            let tintD: Color = WrappedPalette.periwinkle.opacity(0.85)

            return ZStack {
                BlobShape()
                    .fill(tintC)
                    .frame(width: width * 0.88, height: width * 0.72)
                    .rotationEffect(.degrees(-10 + Double(index % 3) * 4))
                    .offset(x: -width * 0.18, y: -height * 0.36)
                    .shadow(color: tintC.opacity(0.35), radius: 36, x: -10, y: -10)

                BlobShape()
                    .fill(tintB)
                    .frame(width: width * 0.70, height: width * 0.92)
                    .rotationEffect(.degrees(18 + Double(index % 4) * 4))
                    .offset(x: width * 0.48, y: -height * 0.28)
                    .shadow(color: tintB.opacity(0.3), radius: 28, x: 10, y: 16)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tintD)
                    .frame(width: width * 0.86, height: 5)
                    .offset(y: height * 0.12)

                Capsule(style: .continuous)
                    .fill(WrappedPalette.highlight.opacity(0.95))
                    .frame(width: width * 0.50, height: 42)
                    .rotationEffect(.degrees(-14))
                    .offset(x: -width * 0.14, y: height * 0.30)

                WavyRibbon(amplitude: 18, frequency: 5)
                    .stroke(tintA, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: width * 0.86, height: 120)
                    .offset(y: height * 0.26)
            }
            .blendMode(.normal)
        }
    }
}

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            path.move(to: CGPoint(x: 0.95 * width, y: 0.37 * height))
            path.addCurve(
                to: CGPoint(x: 0.66 * width, y: 0.95 * height),
                control1: CGPoint(x: 1.02 * width, y: 0.67 * height),
                control2: CGPoint(x: 0.92 * width, y: 1.02 * height)
            )
            path.addCurve(
                to: CGPoint(x: 0.1 * width, y: 0.72 * height),
                control1: CGPoint(x: 0.4 * width, y: 0.9 * height),
                control2: CGPoint(x: 0.28 * width, y: 0.8 * height)
            )
            path.addCurve(
                to: CGPoint(x: 0.32 * width, y: 0.08 * height),
                control1: CGPoint(x: -0.08 * width, y: 0.64 * height),
                control2: CGPoint(x: 0.02 * width, y: 0.1 * height)
            )
            path.addCurve(
                to: CGPoint(x: 0.95 * width, y: 0.37 * height),
                control1: CGPoint(x: 0.62 * width, y: 0.05 * height),
                control2: CGPoint(x: 0.88 * width, y: 0.08 * height)
            )
            path.closeSubpath()
        }
    }
}

struct WavyRibbon: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            let step = rect.width / 80
            path.move(to: CGPoint(x: 0, y: rect.midY))
            var x: CGFloat = 0
            while x <= rect.width {
                let relative = x / rect.width
                let y = rect.midY + sin(relative * .pi * frequency) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
                x += step
            }
        }
    }
}

#Preview {
    WrappedView()
}
