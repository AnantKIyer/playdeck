import SwiftUI
import PlaydeckProtocol

/// Dense Stream Deck–style clone — default Deck MVP grid.
struct DeckGridView: View {
    @EnvironmentObject private var model: PhoneAppModel

    private var page: DeckPage {
        model.layout.pages.first ?? DeckPage(name: "Empty", columns: 5, rows: 3)
    }

    private let gap: CGFloat = 8

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let columns = page.columns
                let rows = page.rows
                let totalGapX = gap * CGFloat(columns - 1)
                let totalGapY = gap * CGFloat(rows - 1)
                let cellW = max(44, (geo.size.width - 32 - totalGapX) / CGFloat(columns))
                let cellH = max(44, (geo.size.height - 24 - totalGapY) / CGFloat(rows))

                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < page.buttons.count {
                                    DeckButtonCell(
                                        button: page.buttons[index],
                                        size: CGSize(width: cellW, height: cellH)
                                    ) { phase in
                                        model.invokeButton(page.buttons[index], phase: phase)
                                    }
                                } else {
                                    Color.clear
                                        .frame(width: cellW, height: cellH)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.09, blue: 0.11),
                        Color(red: 0.12, green: 0.14, blue: 0.16),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle(page.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Leave") { model.leaveMode() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Deck")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DeckButtonCell: View {
    let button: DeckButton
    let size: CGSize
    let onPhase: (DeckInvokePhase) -> Void

    @State private var pressed = false

    var body: some View {
        let color = Color(hex: button.colorHex) ?? Color.gray.opacity(0.4)

        VStack(spacing: 6) {
            if let icon = button.iconName {
                Image(systemName: icon)
                    .font(.system(size: min(size.width, size.height) * 0.28))
            }
            Text(button.title)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(width: size.width, height: size.height)
        .background(color.opacity(pressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .scaleEffect(pressed ? 0.96 : 1)
        .animation(.easeOut(duration: 0.12), value: pressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        pressed = true
                        onPhase(.down)
                    }
                }
                .onEnded { _ in
                    pressed = false
                    onPhase(.up)
                }
        )
        .accessibilityLabel(button.title)
    }
}

private extension Color {
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
