import Foundation
import SwiftUI
import Combine

enum ThemePreference: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .dark: return "深色"
        case .light: return "浅色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kvs = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard

    private enum Key {
        static let theme = "pref.theme"
        static let remindLeadDays = "pref.reminderLeadDays"
        static let remindHour = "pref.reminderHour"
        static let defaultCurrency = "pref.defaultCurrency"
        static let usdCnyRate = "pref.usdCnyRate"
        static let notificationsEnabled = "pref.notificationsEnabled"
        static let userName = "pref.userName"
        static let userEmail = "pref.userEmail"
    }

    @Published var theme: ThemePreference {
        didSet { write(theme.rawValue, Key.theme) }
    }

    @Published var reminderLeadDays: Int {
        didSet { write(reminderLeadDays, Key.remindLeadDays) }
    }

    @Published var reminderHour: Int {
        didSet { write(reminderHour, Key.remindHour) }
    }

    @Published var defaultCurrency: CurrencyCode {
        didSet {
            write(defaultCurrency.rawValue, Key.defaultCurrency)
            AppGroup.sharedDefaults.set(defaultCurrency.rawValue, forKey: AppGroup.SharedKey.displayCurrency)
        }
    }

    @Published var usdCnyRate: Double {
        didSet {
            write(usdCnyRate, Key.usdCnyRate)
            AppGroup.sharedDefaults.set(usdCnyRate, forKey: AppGroup.SharedKey.usdCnyRate)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet { write(notificationsEnabled, Key.notificationsEnabled) }
    }

    @Published var userName: String {
        didSet { write(userName, Key.userName) }
    }

    @Published var userEmail: String {
        didSet { write(userEmail, Key.userEmail) }
    }

    private init() {
        let kvs = NSUbiquitousKeyValueStore.default
        let defaults = UserDefaults.standard
        kvs.synchronize()

        func getString(_ k: String, _ fallback: String) -> String {
            kvs.string(forKey: k) ?? defaults.string(forKey: k) ?? fallback
        }
        func getInt(_ k: String, _ fallback: Int) -> Int {
            if kvs.object(forKey: k) != nil { return Int(kvs.longLong(forKey: k)) }
            if defaults.object(forKey: k) != nil { return defaults.integer(forKey: k) }
            return fallback
        }
        func getDouble(_ k: String, _ fallback: Double) -> Double {
            if kvs.object(forKey: k) != nil { return kvs.double(forKey: k) }
            if defaults.object(forKey: k) != nil { return defaults.double(forKey: k) }
            return fallback
        }
        func getBool(_ k: String, _ fallback: Bool) -> Bool {
            if kvs.object(forKey: k) != nil { return kvs.bool(forKey: k) }
            if defaults.object(forKey: k) != nil { return defaults.bool(forKey: k) }
            return fallback
        }

        self.theme = ThemePreference(rawValue: getString(Key.theme, ThemePreference.system.rawValue)) ?? .system
        self.reminderLeadDays = getInt(Key.remindLeadDays, 3)
        self.reminderHour = getInt(Key.remindHour, 9)
        let ccy = CurrencyCode(rawValue: getString(Key.defaultCurrency, CurrencyCode.cny.rawValue)) ?? .cny
        self.defaultCurrency = ccy
        let rate = getDouble(Key.usdCnyRate, 7.25)
        self.usdCnyRate = rate
        self.notificationsEnabled = getBool(Key.notificationsEnabled, true)
        self.userName = getString(Key.userName, "我")
        self.userEmail = getString(Key.userEmail, "")

        // Mirror to App Group so widgets can read
        AppGroup.sharedDefaults.set(rate, forKey: AppGroup.SharedKey.usdCnyRate)
        AppGroup.sharedDefaults.set(ccy.rawValue, forKey: AppGroup.SharedKey.displayCurrency)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(kvsChanged(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs
        )
    }

    private func write(_ value: Any, _ key: String) {
        kvs.set(value, forKey: key)
        defaults.set(value, forKey: key)
        kvs.synchronize()
    }

    @objc private func kvsChanged(_ note: Notification) {
        Task { @MainActor in
            if let raw = kvs.string(forKey: Key.theme),
               let v = ThemePreference(rawValue: raw),
               v != self.theme { self.theme = v }

            if kvs.object(forKey: Key.remindLeadDays) != nil {
                let lead = Int(kvs.longLong(forKey: Key.remindLeadDays))
                if lead != self.reminderLeadDays { self.reminderLeadDays = lead }
            }
            if kvs.object(forKey: Key.remindHour) != nil {
                let hour = Int(kvs.longLong(forKey: Key.remindHour))
                if hour != self.reminderHour { self.reminderHour = hour }
            }
            if let raw = kvs.string(forKey: Key.defaultCurrency),
               let v = CurrencyCode(rawValue: raw),
               v != self.defaultCurrency { self.defaultCurrency = v }
            if kvs.object(forKey: Key.usdCnyRate) != nil {
                let rate = kvs.double(forKey: Key.usdCnyRate)
                if rate > 0, rate != self.usdCnyRate { self.usdCnyRate = rate }
            }
            if kvs.object(forKey: Key.notificationsEnabled) != nil {
                let v = kvs.bool(forKey: Key.notificationsEnabled)
                if v != self.notificationsEnabled { self.notificationsEnabled = v }
            }
        }
    }
}
