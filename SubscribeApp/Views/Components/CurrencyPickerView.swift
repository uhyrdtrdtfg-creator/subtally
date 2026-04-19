import SwiftUI

/// A sheet-presentable currency picker with search + region grouping.
/// Usage:
///   .sheet(isPresented: $show) {
///       CurrencyPickerView(selection: $currency) { show = false }
///   }
struct CurrencyPickerView: View {
    @Binding var selection: CurrencyCode
    var onDone: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var groups: [(CurrencyRegion, [CurrencyCode])] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return CurrencyCatalog.grouped() }
        let hits = CurrencyCatalog.search(q)
        let dict = Dictionary(grouping: hits, by: \.region)
        let order: [CurrencyRegion] = [.mainstream, .africa, .other]
        return order.compactMap { r -> (CurrencyRegion, [CurrencyCode])? in
            guard let codes = dict[r], !codes.isEmpty else { return nil }
            return (r, codes.sorted { $0.displayName < $1.displayName })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.0) { region, codes in
                    Section(region.displayName) {
                        ForEach(codes) { code in
                            Button {
                                selection = code
                                onDone()
                                dismiss()
                            } label: {
                                HStack {
                                    Text(code.symbol)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(width: 44, alignment: .leading)
                                        .foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(code.displayName).foregroundStyle(.primary)
                                        Text(code.rawValue).font(.caption2).foregroundStyle(.secondary).monospaced()
                                    }
                                    Spacer()
                                    if code == selection {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索币种 / ISO 代码")
            .navigationTitle("选择币种")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { onDone(); dismiss() }
                }
            }
        }
    }
}

/// A compact row that shows current currency and opens the picker on tap.
/// Drop into a Form Section.
struct CurrencyPickerRow: View {
    let label: String
    @Binding var selection: CurrencyCode
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 6) {
                    Text(selection.symbol).foregroundStyle(.secondary)
                    Text(selection.rawValue).foregroundStyle(.secondary).monospaced()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            CurrencyPickerView(selection: $selection)
        }
    }
}
