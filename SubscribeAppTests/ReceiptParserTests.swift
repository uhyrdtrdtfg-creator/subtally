import XCTest
@testable import Subtally

/// Tests for `ReceiptParser.parse(text:)`. The parser is a pure function so
/// no SwiftData / app-state setup is required.
final class ReceiptParserTests: XCTestCase {

    // MARK: - Helpers

    private func ymd(_ y: Int, _ m: Int, _ d: Int) -> DateComponents {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return c
    }

    private func components(of date: Date) -> DateComponents {
        let cal = Calendar(identifier: .gregorian)
        return cal.dateComponents([.year, .month, .day], from: date)
    }

    // MARK: - Tests

    func test_appleMusicReceipt_parsesNameAmountCurrencyAndDate() {
        let text = "Apple Music\n¥10.99/月\n2026-04-18"
        let info = ReceiptParser.parse(text: text)

        XCTAssertEqual(info.merchant, "Apple Music")
        XCTAssertEqual(info.amount ?? .nan, 10.99, accuracy: 0.001)
        XCTAssertEqual(info.currency, .cny)
        XCTAssertNotNil(info.date)
        if let d = info.date {
            let c = components(of: d)
            XCTAssertEqual(c.year, 2026)
            XCTAssertEqual(c.month, 4)
            XCTAssertEqual(c.day, 18)
        }
        XCTAssertEqual(info.rawText, text)
    }

    func test_wechatPayChineseDate_parses() {
        let text = "网易云音乐 黑胶VIP\n¥15.00\n2026年4月18日"
        let info = ReceiptParser.parse(text: text)

        XCTAssertEqual(info.merchant, "网易云音乐")
        XCTAssertEqual(info.amount ?? .nan, 15.0, accuracy: 0.001)
        XCTAssertEqual(info.currency, .cny)
        XCTAssertNotNil(info.date)
        if let d = info.date {
            let c = components(of: d)
            XCTAssertEqual(c.year, 2026)
            XCTAssertEqual(c.month, 4)
            XCTAssertEqual(c.day, 18)
        }
    }

    func test_alipaySlashDateAndYuanSuffix_parses() {
        let text = "腾讯视频会员\n¥25 元\n2026/04/18"
        let info = ReceiptParser.parse(text: text)

        XCTAssertEqual(info.merchant, "腾讯视频")
        XCTAssertNotNil(info.amount)
        XCTAssertEqual(info.amount!, 25.0, accuracy: 0.001)
        XCTAssertEqual(info.currency, .cny)
        XCTAssertNotNil(info.date)
        if let d = info.date {
            let c = components(of: d)
            XCTAssertEqual(c.year, 2026)
            XCTAssertEqual(c.month, 4)
            XCTAssertEqual(c.day, 18)
        }
    }

    func test_englishSpotifyReceipt_parses() {
        let text = "Spotify Premium\n$10.99\nApr 18, 2026"
        let info = ReceiptParser.parse(text: text)

        XCTAssertEqual(info.merchant, "Spotify")
        XCTAssertEqual(info.amount ?? .nan, 10.99, accuracy: 0.001)
        XCTAssertEqual(info.currency, .usd)
        XCTAssertNotNil(info.date)
        if let d = info.date {
            let c = components(of: d)
            XCTAssertEqual(c.year, 2026)
            XCTAssertEqual(c.month, 4)
            XCTAssertEqual(c.day, 18)
        }
    }

    func test_emptyInput_allFieldsNil() {
        let info = ReceiptParser.parse(text: "")
        XCTAssertNil(info.merchant)
        XCTAssertNil(info.amount)
        XCTAssertNil(info.currency)
        XCTAssertNil(info.date)
        XCTAssertEqual(info.rawText, "")
    }

    func test_garbageInput_setsRawTextOnly() {
        let garbage = "??? !!! ###"
        let info = ReceiptParser.parse(text: garbage)
        XCTAssertNil(info.amount)
        XCTAssertNil(info.currency)
        XCTAssertNil(info.date)
        // merchant falls back to first non-empty line, so it'll be "??? !!! ###"
        // but rawText must always reflect the input.
        XCTAssertEqual(info.rawText, garbage)
    }

    func test_mixedCurrencies_picksLargestAmountWithMatchingCurrency() {
        // Two currencies in same text. Parser picks the largest by `value`.
        // ¥99 > $5.00 so we expect CNY 99.
        let text = "Some Service\n$5.00\nrefund: ¥99\n2026-04-18"
        let info = ReceiptParser.parse(text: text)

        XCTAssertNotNil(info.amount)
        XCTAssertEqual(info.amount!, 99.0, accuracy: 0.001)
        XCTAssertEqual(info.currency, .cny)
    }

    func test_brandAliasMatching_iqiyiLowercase_returnsCanonicalChinese() {
        let text = "iqiyi vip\n¥19.80\n2026-04-18"
        let info = ReceiptParser.parse(text: text)
        XCTAssertEqual(info.merchant, "爱奇艺")
    }

    func test_dashedDateIsParsed() {
        // Dashed date should parse.
        let dashed = "Some Service\n¥10\n2026-04-18"
        let dashedInfo = ReceiptParser.parse(text: dashed)
        XCTAssertNotNil(dashedInfo.date)
    }

    func test_amountWithComma_documentsBehavior() {
        // The regex `[0-9]+(?:\.[0-9]{1,2})?` does NOT match thousands
        // separators. "¥10,000" will match the leading "¥10" only.
        let text = "Big Service\n¥10,000\n2026-04-18"
        let info = ReceiptParser.parse(text: text)
        XCTAssertNotNil(info.amount)
        XCTAssertEqual(info.amount!, 10.0, accuracy: 0.001,
                       "Comma-grouped numbers should be treated as the leading run only")
        XCTAssertEqual(info.currency, .cny)
    }

    func test_cnySuffixForms_USDTextual() {
        // "20 USD" form
        let text = "OpenAI\n20 USD\n2026-04-18"
        let info = ReceiptParser.parse(text: text)
        XCTAssertEqual(info.merchant, "OpenAI")
        XCTAssertEqual(info.amount ?? .nan, 20.0, accuracy: 0.001)
        XCTAssertEqual(info.currency, .usd)
    }

    func test_rmbPrefix_treatedAsCNY() {
        let text = "Some Service\nRMB 50\n2026-04-18"
        let info = ReceiptParser.parse(text: text)
        XCTAssertEqual(info.amount ?? .nan, 50.0, accuracy: 0.001)
        XCTAssertEqual(info.currency, .cny)
    }
}
