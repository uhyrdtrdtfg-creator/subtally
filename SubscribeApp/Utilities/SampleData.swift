import Foundation
import SwiftData

enum SampleData {
    struct Seed {
        let name: String
        let cat: SubscriptionCategory
        let price: Double
        let ccy: CurrencyCode
        let cycle: BillingCycle
        let next: String
        let slug: String
        let color: String
        let letter: String
    }

    static let seeds: [Seed] = [
        .init(name: "Netflix",        cat: .video, price: 68,  ccy: .cny, cycle: .month, next: "2026-04-21", slug: "netflix",           color: "E50914", letter: "N"),
        .init(name: "爱奇艺",          cat: .video, price: 25,  ccy: .cny, cycle: .month, next: "2026-04-23", slug: "iqiyi",             color: "00BE06", letter: "爱"),
        .init(name: "百度网盘",        cat: .cloud, price: 30,  ccy: .cny, cycle: .month, next: "2026-04-25", slug: "baidu",             color: "2932E1", letter: "度"),
        .init(name: "Spotify",        cat: .music, price: 30,  ccy: .cny, cycle: .month, next: "2026-04-27", slug: "spotify",           color: "1DB954", letter: "S"),
        .init(name: "iCloud+ 200GB",  cat: .cloud, price: 21,  ccy: .cny, cycle: .month, next: "2026-04-30", slug: "icloud",            color: "3193FF", letter: "☁"),
        .init(name: "网易云音乐",       cat: .music, price: 15,  ccy: .cny, cycle: .month, next: "2026-05-03", slug: "neteasecloudmusic", color: "C20C0C", letter: "云"),
        .init(name: "ChatGPT Plus",   cat: .ai,    price: 20,  ccy: .usd, cycle: .month, next: "2026-05-06", slug: "openai",            color: "10A37F", letter: "G"),
        .init(name: "B站大会员",       cat: .video, price: 168, ccy: .cny, cycle: .year,  next: "2026-05-10", slug: "bilibili",          color: "00A1D6", letter: "B"),
        .init(name: "Adobe Creative", cat: .work,  price: 29,  ccy: .usd, cycle: .month, next: "2026-05-14", slug: "adobe",             color: "FF0000", letter: "A"),
        .init(name: "Notion Plus",    cat: .work,  price: 10,  ccy: .usd, cycle: .month, next: "2026-05-21", slug: "notion",            color: "000000", letter: "N"),
        .init(name: "Claude Pro",     cat: .ai,    price: 20,  ccy: .usd, cycle: .month, next: "2026-05-28", slug: "anthropic",         color: "D97757", letter: "C"),
        .init(name: "京东 PLUS",       cat: .work,  price: 299, ccy: .cny, cycle: .year,  next: "2026-06-02", slug: "jd",                color: "E1251B", letter: "京"),
    ]

    static func ensureSeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        let trialNames: Set<String> = ["Claude Pro"]

        for s in seeds {
            guard let date = formatter.date(from: s.next) else { continue }
            let isTrial = trialNames.contains(s.name)
            let trialEnd: Date? = isTrial
                ? Calendar(identifier: .gregorian).date(byAdding: .day, value: 2, to: Date())
                : nil
            let sub = Subscription(
                name: s.name,
                category: s.cat,
                price: s.price,
                currency: s.ccy,
                cycle: s.cycle,
                nextBillingDate: date,
                slug: s.slug,
                brandColorHex: s.color,
                fallbackLetter: s.letter,
                isFreeTrial: isTrial,
                trialEndDate: trialEnd
            )
            context.insert(sub)
        }
        try? context.save()
    }
}
