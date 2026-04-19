import SwiftUI

struct SharedBillingSection: View {
    @Binding var totalShares: Int
    @Binding var mineShares: Int
    @Binding var note: String
    let totalPriceText: String

    @Environment(\.palette) private var palette
    @State private var sharedOn: Bool = false

    init(
        totalShares: Binding<Int>,
        mineShares: Binding<Int>,
        note: Binding<String>,
        totalPriceText: String
    ) {
        self._totalShares = totalShares
        self._mineShares = mineShares
        self._note = note
        self.totalPriceText = totalPriceText
    }

    var body: some View {
        Section {
            Toggle("和别人分摊", isOn: Binding(
                get: { sharedOn },
                set: { newValue in
                    sharedOn = newValue
                    if newValue {
                        if totalShares < 2 { totalShares = 2 }
                        if mineShares < 1 { mineShares = 1 }
                        if mineShares > totalShares { mineShares = totalShares }
                    } else {
                        totalShares = 1
                        mineShares = 1
                        note = ""
                    }
                }
            ))

            if sharedOn {
                Stepper(value: Binding(
                    get: { totalShares },
                    set: { newValue in
                        let clamped = max(1, min(20, newValue))
                        totalShares = clamped
                        if mineShares > clamped { mineShares = clamped }
                    }
                ), in: 1...20) {
                    HStack {
                        Text("总共多少人分")
                        Spacer()
                        Text("\(totalShares)")
                            .foregroundStyle(palette.ink2)
                    }
                }

                Stepper(value: Binding(
                    get: { mineShares },
                    set: { newValue in
                        mineShares = max(1, min(totalShares, newValue))
                    }
                ), in: 1...max(1, totalShares)) {
                    HStack {
                        Text("我承担几份")
                        Spacer()
                        Text("\(mineShares)")
                            .foregroundStyle(palette.ink2)
                    }
                }

                TextField("和女友 AA / Apple One 家庭组", text: $note)

                HStack {
                    Text("我每期付")
                        .foregroundStyle(palette.ink2)
                    Spacer()
                    Text(previewText)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
            }
        } header: {
            Text("分账")
        } footer: {
            Text("选了“和别人分摊”后，趋势页与本月支出会按你承担的份额计算。")
        }
        .onAppear {
            sharedOn = totalShares > 1
        }
    }

    private var previewText: String {
        let (symbol, amount) = parsePrice(totalPriceText)
        let denom = max(1, totalShares)
        let share = amount / Double(denom) * Double(max(0, min(mineShares, totalShares)))
        return "\(symbol)\(formatAmount(share))"
    }

    private func parsePrice(_ text: String) -> (String, Double) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var symbol = ""
        var numericPart = trimmed
        if let first = trimmed.first, !first.isNumber, first != "." && first != "-" {
            symbol = String(first)
            numericPart = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        let cleaned = numericPart.filter { $0.isNumber || $0 == "." || $0 == "-" }
        let value = Double(cleaned) ?? 0
        if symbol.isEmpty { symbol = "¥" }
        return (symbol, value)
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
