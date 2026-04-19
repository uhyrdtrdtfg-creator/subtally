import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (SubscriptionTemplate) -> Void

    @State private var search: String = ""

    private var filtered: [(SubscriptionCategory, [SubscriptionTemplate])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return SubscriptionTemplate.grouped() }
        return SubscriptionTemplate.grouped().compactMap { (cat, items) in
            let hits = items.filter { $0.name.lowercased().contains(q) }
            return hits.isEmpty ? nil : (cat, hits)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.0) { (cat, items) in
                    Section(cat.displayName) {
                        ForEach(items) { t in
                            Button {
                                onSelect(t)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    BrandIcon(slug: t.slug, colorHex: t.colorHex, fallbackLetter: t.letter, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.name).font(.body).foregroundStyle(.primary)
                                        Text("\(t.suggestedCurrency.symbol)\(formatted(t.suggestedPrice)) · \(t.suggestedCycle.displayName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle").foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索常见服务")
            .navigationTitle("从模板添加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func formatted(_ v: Double) -> String {
        abs(v - v.rounded()) < 0.01 ? "\(Int(v))" : String(format: "%.2f", v)
    }
}
