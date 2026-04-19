import Foundation

/// Parsed receipt info extracted from OCR'd text.
struct ReceiptInfo {
    var merchant: String?
    var amount: Double?
    var currency: CurrencyCode?
    var date: Date?
    var rawText: String

    init(
        merchant: String? = nil,
        amount: Double? = nil,
        currency: CurrencyCode? = nil,
        date: Date? = nil,
        rawText: String = ""
    ) {
        self.merchant = merchant
        self.amount = amount
        self.currency = currency
        self.date = date
        self.rawText = rawText
    }
}

/// Pure / testable parser turning a raw OCR string into a `ReceiptInfo`.
enum ReceiptParser {

    // MARK: - Brand whitelist
    // Canonical display name → lowercased aliases to match inside text.
    // Order matters: we iterate this list so longer / more-specific names win first.
    private static let knownBrands: [(canonical: String, aliases: [String])] = [
        ("Apple Music",    ["apple music"]),
        ("Apple TV",       ["apple tv", "apple tv+", "apple tv plus"]),
        ("iCloud",         ["icloud", "icloud+"]),
        ("Netflix",        ["netflix"]),
        ("Spotify",        ["spotify"]),
        ("Adobe",          ["adobe", "creative cloud"]),
        ("ChatGPT",        ["chatgpt", "chat gpt"]),
        ("OpenAI",         ["openai", "open ai"]),
        ("Claude",         ["claude.ai", "claude"]),
        ("Anthropic",      ["anthropic"]),
        ("Notion",         ["notion"]),
        ("Figma",          ["figma"]),
        ("GitHub",         ["github"]),
        ("Bilibili",       ["bilibili", "b站", "哔哩哔哩"]),
        ("爱奇艺",          ["爱奇艺", "iqiyi"]),
        ("腾讯视频",         ["腾讯视频", "tencent video"]),
        ("芒果",            ["芒果tv", "芒果"]),
        ("网易云音乐",        ["网易云音乐", "网易云", "netease cloud music"]),
        ("百度网盘",         ["百度网盘", "baidu netdisk"]),
        ("京东 PLUS",       ["京东plus", "京东 plus", "jd plus"]),
        ("淘宝",            ["淘宝", "taobao"]),
        ("美团",            ["美团", "meituan"]),
        ("支付宝",           ["支付宝", "alipay"]),
        ("微信支付",          ["微信支付", "wechat pay", "weixin pay"]),
        ("PayPal",         ["paypal"]),
        ("Google",         ["google"]),
        ("Youtube",        ["youtube", "youtube premium"]),
        ("Cursor",         ["cursor"]),
        ("Linear",         ["linear"]),
        ("Midjourney",     ["midjourney"]),
    ]

    // MARK: - Date formatters (evaluated in order)
    private static let dateFormatters: [DateFormatter] = {
        func make(_ format: String, _ localeID: String) -> DateFormatter {
            let df = DateFormatter()
            df.locale = Locale(identifier: localeID)
            df.dateFormat = format
            return df
        }
        return [
            // Chinese locale first for zh formats
            make("yyyy年M月d日", "zh_CN"),
            make("yyyy年MM月dd日", "zh_CN"),
            make("yyyy-MM-dd", "en_US_POSIX"),
            make("yyyy/MM/dd", "en_US_POSIX"),
            make("MMM d, yyyy", "en_US_POSIX"),
            make("MMM d yyyy", "en_US_POSIX"),
        ]
    }()

    // MARK: - Public API

    static func parse(text: String) -> ReceiptInfo {
        var info = ReceiptInfo(rawText: text)
        let lines = splitLines(text)

        let amountMatch = extractAmount(text: text)
        info.amount = amountMatch?.value
        info.currency = amountMatch?.currency

        info.date = extractDate(lines: lines, fullText: text)
        info.merchant = extractMerchant(lines: lines, fullText: text, amountLineIndex: amountMatch?.lineIndex)

        return info
    }

    // MARK: - Amount

    private struct AmountMatch {
        let value: Double
        let currency: CurrencyCode?
        let lineIndex: Int?
    }

    /// Extract the "largest reasonable" amount that looks like a currency figure.
    /// We scan with several regexes; each candidate also tries to nail down a currency.
    private static func extractAmount(text: String) -> AmountMatch? {
        let lines = splitLines(text)

        struct Candidate {
            let value: Double
            let currency: CurrencyCode?
            let lineIndex: Int?
        }
        var candidates: [Candidate] = []

        // Regex patterns: each must produce (numeric, currency-hint)
        // Order mirrors the supported formats in the spec.
        let patterns: [(regex: String, currencyResolver: (String) -> CurrencyCode?)] = [
            // ¥12.99 or ¥ 12.99 or ¥12
            (#"¥\s*([0-9]+(?:\.[0-9]{1,2})?)"#, { _ in .cny }),
            // $20.00
            (#"\$\s*([0-9]+(?:\.[0-9]{1,2})?)"#, { _ in .usd }),
            // 20.00 USD / 20 USD
            (#"([0-9]+(?:\.[0-9]{1,2})?)\s*USD"#, { _ in .usd }),
            // 12.99 元 / 12 元
            (#"([0-9]+(?:\.[0-9]{1,2})?)\s*元"#, { _ in .cny }),
            // CNY 50 / CNY 50.00
            (#"CNY\s*([0-9]+(?:\.[0-9]{1,2})?)"#, { _ in .cny }),
            // RMB 50 (bonus)
            (#"RMB\s*([0-9]+(?:\.[0-9]{1,2})?)"#, { _ in .cny }),
        ]

        for (idx, line) in lines.enumerated() {
            // Skip obviously non-amount noise like "30%".
            // We still scan the line but percents will not match our currency-bearing patterns.
            for (pattern, resolver) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                regex.enumerateMatches(in: line, options: [], range: range) { match, _, _ in
                    guard let match, match.numberOfRanges >= 2,
                          let numRange = Range(match.range(at: 1), in: line),
                          let value = Double(line[numRange]) else { return }
                    // Ignore unreasonably tiny numbers (likely quantities/percents without context).
                    // Currency-tagged <0.5 is suspicious; real subscriptions are typically >= $0.99.
                    guard value >= 0.5 else { return }
                    // Upper sanity bound to avoid picking up giant IDs.
                    guard value < 1_000_000 else { return }
                    let cur = resolver(line)
                    candidates.append(Candidate(value: value, currency: cur, lineIndex: idx))
                }
            }
        }

        guard !candidates.isEmpty else { return nil }

        // Pick the largest "reasonable" amount.
        let best = candidates.max(by: { $0.value < $1.value })!
        return AmountMatch(value: best.value, currency: best.currency, lineIndex: best.lineIndex)
    }

    // MARK: - Date

    private static func extractDate(lines: [String], fullText: String) -> Date? {
        // Try each formatter against each line, plus some regex-extracted substrings.
        // 1) Regex-extract obvious date tokens first (most reliable)
        let tokenRegexes: [String] = [
            #"\d{4}年\d{1,2}月\d{1,2}日"#,
            #"\d{4}-\d{2}-\d{2}"#,
            #"\d{4}/\d{1,2}/\d{1,2}"#,
            #"[A-Za-z]{3,9} \d{1,2},? \d{4}"#,
        ]
        for pattern in tokenRegexes {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(fullText.startIndex..<fullText.endIndex, in: fullText)
            let matches = regex.matches(in: fullText, options: [], range: range)
            for m in matches {
                guard let r = Range(m.range, in: fullText) else { continue }
                let token = String(fullText[r])
                if let d = tryParseDate(token) { return d }
            }
        }
        // 2) Fallback: try whole lines
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let d = tryParseDate(trimmed) { return d }
        }
        return nil
    }

    private static func tryParseDate(_ s: String) -> Date? {
        for df in dateFormatters {
            if let d = df.date(from: s) { return d }
        }
        return nil
    }

    // MARK: - Merchant

    private static func extractMerchant(lines: [String], fullText: String, amountLineIndex: Int?) -> String? {
        // Priority 1: known-brand whitelist
        let lower = fullText.lowercased()
        for brand in knownBrands {
            for alias in brand.aliases {
                if lower.contains(alias.lowercased()) {
                    return brand.canonical
                }
            }
        }

        // Priority 2: line immediately before/after the amount line, if non-date and 2..20 chars
        if let idx = amountLineIndex {
            let candidates = [idx - 1, idx + 1]
                .filter { $0 >= 0 && $0 < lines.count }
            for cIdx in candidates {
                let candidate = lines[cIdx].trimmingCharacters(in: .whitespaces)
                if isReasonableMerchantLine(candidate) { return candidate }
            }
        }

        // Priority 3: first non-empty line
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func isReasonableMerchantLine(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        // Character count (handles CJK correctly via Swift's .count)
        guard s.count >= 2 && s.count <= 20 else { return false }
        // Reject lines that parse as a date
        if tryParseDate(s) != nil { return false }
        // Reject lines that are mostly digits/currency symbols
        let digitSet = CharacterSet(charactersIn: "0123456789.,¥$元 ")
        let nonDigit = s.unicodeScalars.filter { !digitSet.contains($0) }
        if nonDigit.isEmpty { return false }
        return true
    }

    // MARK: - Helpers

    private static func splitLines(_ text: String) -> [String] {
        text
            .split(whereSeparator: { $0.isNewline })
            .map { String($0) }
    }
}
