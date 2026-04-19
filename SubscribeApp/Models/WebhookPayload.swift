import Foundation

struct WebhookPayload: Codable {
    let event: String
    let timestamp: Date
    let app: String
    let appVersion: String
    let deliveryID: String
    let subscription: SubscriptionDTO

    init(event: WebhookEvent, sub: Subscription, usdCnyRate: Double) {
        self.event = event.rawValue
        self.timestamp = Date()
        self.app = "Subscribe iOS"
        self.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        self.deliveryID = UUID().uuidString
        self.subscription = SubscriptionDTO(sub: sub, usdCnyRate: usdCnyRate)
    }
}

struct SubscriptionDTO: Codable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let currency: String
    let cycle: String
    let nextBillingDate: Date
    let isFreeTrial: Bool
    let trialEndDate: Date?
    let priceInCNY: Double
    let monthlyCostCNY: Double

    init(sub: Subscription, usdCnyRate: Double) {
        self.id = sub.stableID
        self.name = sub.name
        self.category = sub.categoryRaw
        self.price = sub.price
        self.currency = sub.currencyRaw
        self.cycle = sub.cycleRaw
        self.nextBillingDate = sub.nextBillingDate
        self.isFreeTrial = sub.isFreeTrial
        self.trialEndDate = sub.trialEndDate
        self.priceInCNY = sub.priceInCNY(usdRate: usdCnyRate)
        self.monthlyCostCNY = sub.monthlyCostCNY(usdRate: usdCnyRate)
    }
}

enum WebhookEncoder {
    static let shared: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}
