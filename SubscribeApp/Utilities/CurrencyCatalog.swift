import Foundation

enum CurrencyCatalog {
    /// Currencies grouped by region in display order. Returns array of (region, [codes]).
    static func grouped() -> [(CurrencyRegion, [CurrencyCode])] {
        let groups = Dictionary(grouping: CurrencyCode.allCases, by: \.region)
        let order: [CurrencyRegion] = [.mainstream, .africa, .other]
        return order.compactMap { region -> (CurrencyRegion, [CurrencyCode])? in
            guard let codes = groups[region], !codes.isEmpty else { return nil }
            return (region, codes.sorted { $0.displayName < $1.displayName })
        }
    }

    /// Search across rawValue, symbol, displayName.
    static func search(_ query: String) -> [CurrencyCode] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return CurrencyCode.allCases }
        return CurrencyCode.allCases.filter { c in
            c.rawValue.lowercased().contains(q) ||
            c.displayName.lowercased().contains(q) ||
            c.symbol.lowercased().contains(q)
        }
    }
}
