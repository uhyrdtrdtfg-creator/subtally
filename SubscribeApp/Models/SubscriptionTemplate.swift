import Foundation

struct SubscriptionTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: SubscriptionCategory
    let suggestedPrice: Double
    let suggestedCurrency: CurrencyCode
    let suggestedCycle: BillingCycle
    let slug: String
    let colorHex: String
    let letter: String

    static let all: [SubscriptionTemplate] = [
        // VIDEO
        .init(id: "netflix", name: "Netflix", category: .video, suggestedPrice: 68, suggestedCurrency: .cny, suggestedCycle: .month, slug: "netflix", colorHex: "E50914", letter: "N"),
        .init(id: "iqiyi", name: "爱奇艺", category: .video, suggestedPrice: 25, suggestedCurrency: .cny, suggestedCycle: .month, slug: "iqiyi", colorHex: "00BE06", letter: "爱"),
        .init(id: "youku", name: "优酷", category: .video, suggestedPrice: 20, suggestedCurrency: .cny, suggestedCycle: .month, slug: "", colorHex: "1A8CFF", letter: "优"),
        .init(id: "tencent_video", name: "腾讯视频", category: .video, suggestedPrice: 25, suggestedCurrency: .cny, suggestedCycle: .month, slug: "tencentqq", colorHex: "1EBAFC", letter: "腾"),
        .init(id: "mango_tv", name: "芒果 TV", category: .video, suggestedPrice: 19, suggestedCurrency: .cny, suggestedCycle: .month, slug: "", colorHex: "FF6600", letter: "芒"),
        .init(id: "bilibili", name: "B 站大会员", category: .video, suggestedPrice: 168, suggestedCurrency: .cny, suggestedCycle: .year, slug: "bilibili", colorHex: "00A1D6", letter: "B"),
        .init(id: "youtube_premium", name: "YouTube Premium", category: .video, suggestedPrice: 13.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "youtube", colorHex: "FF0000", letter: "Y"),
        .init(id: "disney_plus", name: "Disney+", category: .video, suggestedPrice: 10.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "disney", colorHex: "113CCF", letter: "D"),
        .init(id: "hbo_max", name: "HBO Max", category: .video, suggestedPrice: 15.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "hbo", colorHex: "8A00C4", letter: "H"),
        .init(id: "prime_video", name: "Prime Video", category: .video, suggestedPrice: 8.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "amazonprime", colorHex: "00A8E1", letter: "P"),
        .init(id: "apple_tv", name: "Apple TV+", category: .video, suggestedPrice: 9.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "appletv", colorHex: "000000", letter: ""),

        // MUSIC
        .init(id: "spotify", name: "Spotify", category: .music, suggestedPrice: 30, suggestedCurrency: .cny, suggestedCycle: .month, slug: "spotify", colorHex: "1DB954", letter: "S"),
        .init(id: "apple_music", name: "Apple Music", category: .music, suggestedPrice: 10.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "applemusic", colorHex: "FA243C", letter: "♪"),
        .init(id: "netease_music", name: "网易云音乐", category: .music, suggestedPrice: 15, suggestedCurrency: .cny, suggestedCycle: .month, slug: "neteasecloudmusic", colorHex: "C20C0C", letter: "云"),
        .init(id: "qq_music", name: "QQ 音乐", category: .music, suggestedPrice: 15, suggestedCurrency: .cny, suggestedCycle: .month, slug: "qq", colorHex: "31C27C", letter: "Q"),
        .init(id: "tidal", name: "Tidal HiFi", category: .music, suggestedPrice: 10.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "tidal", colorHex: "000000", letter: "T"),

        // CLOUD
        .init(id: "icloud_200", name: "iCloud+ 200GB", category: .cloud, suggestedPrice: 21, suggestedCurrency: .cny, suggestedCycle: .month, slug: "icloud", colorHex: "3193FF", letter: "☁"),
        .init(id: "icloud_2tb", name: "iCloud+ 2TB", category: .cloud, suggestedPrice: 68, suggestedCurrency: .cny, suggestedCycle: .month, slug: "icloud", colorHex: "3193FF", letter: "☁"),
        .init(id: "google_one", name: "Google One", category: .cloud, suggestedPrice: 1.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "googleone", colorHex: "4285F4", letter: "G"),
        .init(id: "dropbox", name: "Dropbox Plus", category: .cloud, suggestedPrice: 11.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "dropbox", colorHex: "0061FF", letter: "D"),
        .init(id: "onedrive", name: "OneDrive 1TB", category: .cloud, suggestedPrice: 69.99, suggestedCurrency: .usd, suggestedCycle: .year, slug: "microsoftonedrive", colorHex: "0078D4", letter: "O"),
        .init(id: "baidu_netdisk", name: "百度网盘 超级", category: .cloud, suggestedPrice: 30, suggestedCurrency: .cny, suggestedCycle: .month, slug: "baidu", colorHex: "2932E1", letter: "度"),
        .init(id: "alibaba_cloud_disk", name: "阿里云盘", category: .cloud, suggestedPrice: 15, suggestedCurrency: .cny, suggestedCycle: .month, slug: "alibabadotcom", colorHex: "FF6A00", letter: "阿"),
        .init(id: "backblaze", name: "Backblaze", category: .cloud, suggestedPrice: 9, suggestedCurrency: .usd, suggestedCycle: .month, slug: "backblaze", colorHex: "E80000", letter: "B"),

        // AI
        .init(id: "chatgpt_plus", name: "ChatGPT Plus", category: .ai, suggestedPrice: 20, suggestedCurrency: .usd, suggestedCycle: .month, slug: "openai", colorHex: "10A37F", letter: "G"),
        .init(id: "chatgpt_pro", name: "ChatGPT Pro", category: .ai, suggestedPrice: 200, suggestedCurrency: .usd, suggestedCycle: .month, slug: "openai", colorHex: "10A37F", letter: "G"),
        .init(id: "claude_pro", name: "Claude Pro", category: .ai, suggestedPrice: 20, suggestedCurrency: .usd, suggestedCycle: .month, slug: "anthropic", colorHex: "D97757", letter: "C"),
        .init(id: "claude_max", name: "Claude Max", category: .ai, suggestedPrice: 100, suggestedCurrency: .usd, suggestedCycle: .month, slug: "anthropic", colorHex: "D97757", letter: "C"),
        .init(id: "cursor_pro", name: "Cursor Pro", category: .ai, suggestedPrice: 20, suggestedCurrency: .usd, suggestedCycle: .month, slug: "cursor", colorHex: "000000", letter: "C"),
        .init(id: "github_copilot", name: "GitHub Copilot", category: .ai, suggestedPrice: 10, suggestedCurrency: .usd, suggestedCycle: .month, slug: "github", colorHex: "181717", letter: "©"),
        .init(id: "midjourney", name: "Midjourney", category: .ai, suggestedPrice: 10, suggestedCurrency: .usd, suggestedCycle: .month, slug: "", colorHex: "000000", letter: "M"),
        .init(id: "gemini_advanced", name: "Gemini Advanced", category: .ai, suggestedPrice: 19.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "googlegemini", colorHex: "8E75B2", letter: "G"),
        .init(id: "perplexity_pro", name: "Perplexity Pro", category: .ai, suggestedPrice: 20, suggestedCurrency: .usd, suggestedCycle: .month, slug: "perplexity", colorHex: "20808D", letter: "P"),

        // WORK
        .init(id: "notion_plus", name: "Notion Plus", category: .work, suggestedPrice: 10, suggestedCurrency: .usd, suggestedCycle: .month, slug: "notion", colorHex: "000000", letter: "N"),
        .init(id: "notion_ai", name: "Notion AI", category: .work, suggestedPrice: 8, suggestedCurrency: .usd, suggestedCycle: .month, slug: "notion", colorHex: "000000", letter: "N"),
        .init(id: "figma_pro", name: "Figma Professional", category: .work, suggestedPrice: 15, suggestedCurrency: .usd, suggestedCycle: .month, slug: "figma", colorHex: "F24E1E", letter: "F"),
        .init(id: "adobe_cc", name: "Adobe Creative Cloud", category: .work, suggestedPrice: 29.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "adobe", colorHex: "FF0000", letter: "A"),
        .init(id: "office_365", name: "Microsoft 365", category: .work, suggestedPrice: 6.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "microsoft365", colorHex: "D83B01", letter: "O"),
        .init(id: "slack_pro", name: "Slack Pro", category: .work, suggestedPrice: 8.75, suggestedCurrency: .usd, suggestedCycle: .month, slug: "slack", colorHex: "4A154B", letter: "#"),
        .init(id: "linear", name: "Linear", category: .work, suggestedPrice: 8, suggestedCurrency: .usd, suggestedCycle: .month, slug: "linear", colorHex: "5E6AD2", letter: "L"),
        .init(id: "jd_plus", name: "京东 PLUS", category: .work, suggestedPrice: 299, suggestedCurrency: .cny, suggestedCycle: .year, slug: "jd", colorHex: "E1251B", letter: "京"),
        .init(id: "taobao_88vip", name: "淘宝 88VIP", category: .work, suggestedPrice: 888, suggestedCurrency: .cny, suggestedCycle: .year, slug: "", colorHex: "FF5000", letter: "淘"),
        .init(id: "meituan_plus", name: "美团会员", category: .work, suggestedPrice: 15, suggestedCurrency: .cny, suggestedCycle: .month, slug: "", colorHex: "FFC300", letter: "美"),
        .init(id: "raycast_pro", name: "Raycast Pro", category: .work, suggestedPrice: 8, suggestedCurrency: .usd, suggestedCycle: .month, slug: "raycast", colorHex: "FF6363", letter: "R"),
        .init(id: "1password", name: "1Password", category: .work, suggestedPrice: 2.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "1password", colorHex: "0572EC", letter: "1"),
        .init(id: "setapp", name: "Setapp", category: .work, suggestedPrice: 9.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "setapp", colorHex: "E91E63", letter: "S"),
        .init(id: "readwise", name: "Readwise", category: .work, suggestedPrice: 7.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "", colorHex: "F17F8D", letter: "R"),
        .init(id: "kindle_unlimited", name: "Kindle Unlimited", category: .work, suggestedPrice: 9.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "amazon", colorHex: "FF9900", letter: "K"),
        .init(id: "duolingo_super", name: "Duolingo Super", category: .work, suggestedPrice: 6.99, suggestedCurrency: .usd, suggestedCycle: .month, slug: "duolingo", colorHex: "58CC02", letter: "D"),
        .init(id: "wechat_read", name: "微信读书", category: .work, suggestedPrice: 19, suggestedCurrency: .cny, suggestedCycle: .month, slug: "weread", colorHex: "37A7FF", letter: "读"),
        .init(id: "ximalaya", name: "喜马拉雅 VIP", category: .music, suggestedPrice: 25, suggestedCurrency: .cny, suggestedCycle: .month, slug: "", colorHex: "F86442", letter: "喜"),
        .init(id: "qidian", name: "起点中文网", category: .work, suggestedPrice: 20, suggestedCurrency: .cny, suggestedCycle: .month, slug: "", colorHex: "E12C2C", letter: "起"),
    ]

    static func grouped() -> [(SubscriptionCategory, [SubscriptionTemplate])] {
        let dict = Dictionary(grouping: all, by: \.category)
        return SubscriptionCategory.allCases.compactMap { cat in
            guard let items = dict[cat], !items.isEmpty else { return nil }
            return (cat, items.sorted { $0.name < $1.name })
        }
    }
}
