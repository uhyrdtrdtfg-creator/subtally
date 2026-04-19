import SwiftUI
import SwiftData
import UserNotifications

struct MeView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query private var subs: [Subscription]

    @State private var showProfileEdit = false
    @State private var showReminderSheet = false
    @State private var showCurrencySheet = false
    @State private var showNotificationSheet = false
    @State private var showWebhooks = false
    @State private var showYearInReview = ProcessInfo.processInfo.environment["LAUNCH_SHEET"] == "year"
    @State private var exportURL: URL?
    @State private var showExportShare = false
    @State private var lastSyncText: String = "今天"

    private var yearTotal: Double {
        subs.reduce(0) { $0 + $1.mineMonthlyCostCNY(usdRate: settings.usdCnyRate) } * 12
    }

    private let yearBars: [CGFloat] = [0.75, 0.78, 0.82, 0.84, 0.88, 0.90, 0.91, 0.93, 0.96, 0.98, 1.02, 1.00]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TopBar(eyebrow: "ACCOUNT · PREFERENCES", avatarText: String(settings.userName.prefix(1)).uppercased())
                BigTitle(text: "我的")

                profileCard.padding(.horizontal, 24).padding(.top, 20)
                yearCard.padding(.horizontal, 24).padding(.top, 14)

                preferencesGroup.padding(.horizontal, 24).padding(.top, 22)
                integrationsGroup.padding(.horizontal, 24).padding(.top, 22)
                dataGroup.padding(.horizontal, 24).padding(.top, 22)
                aboutGroup.padding(.horizontal, 24).padding(.top, 22)
            }
        }
        .sheet(isPresented: $showProfileEdit) { ProfileEditView() }
        .sheet(isPresented: $showReminderSheet) { ReminderSettingsView() }
        .sheet(isPresented: $showCurrencySheet) { CurrencySettingsView() }
        .sheet(isPresented: $showNotificationSheet) { NotificationSettingsView() }
        .sheet(isPresented: $showWebhooks) { WebhookSettingsView() }
        .sheet(isPresented: $showYearInReview) {
            YearInReviewView(year: Calendar(identifier: .gregorian).component(.year, from: Date()))
        }
        .sheet(isPresented: $showExportShare) {
            if let url = exportURL { ShareSheet(items: [url]) }
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(LinearGradient(
                    colors: [Color(hex: "3A5A40"), Color(hex: "588157")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                Text(String(settings.userName.prefix(1)).uppercased())
                    .font(AppFont.geist(20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)
            .shadow(color: Color(hex: "3A5A40").opacity(0.3), radius: 7, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.userName)
                    .font(AppFont.geist(17, weight: .semibold))
                    .kerning(-0.3)
                    .foregroundStyle(palette.ink)
                Text(settings.userEmail.isEmpty ? "未设置邮箱" : settings.userEmail)
                    .font(AppFont.geist(12))
                    .foregroundStyle(palette.ink3)
            }
            Spacer()
            Button { showProfileEdit = true } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.ink2)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(palette.cardHi)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.border, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.card)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(palette.border, lineWidth: 1))
        )
    }

    private var yearCard: some View {
        let display = settings.defaultCurrency
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                CardLabel(text: "年度支出")
                Text(Fmt.displayInt(cnyAmount: yearTotal, in: display, usdCnyRate: settings.usdCnyRate))
                    .font(AppFont.geist(30, weight: .bold))
                    .kerning(-0.9)
                    .monospacedDigit()
                    .foregroundStyle(palette.ink)
                    .padding(.top, 2)
                Text("跨 \(subs.count) 个订阅 · 较去年 ↑ 12.4%")
                    .font(AppFont.geist(12))
                    .foregroundStyle(palette.ink3)
                    .padding(.top, 4)
            }
            Spacer()
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(yearBars.enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == 11 ? palette.green : palette.border)
                        .frame(width: 5, height: h * 36)
                }
            }
            .frame(height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.card)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(palette.border, lineWidth: 1))
        )
    }

    private var preferencesGroup: some View {
        SettingsGroup(label: "偏好") {
            SettingsRow(
                icon: "clock",
                title: "提醒时间",
                value: "到期前 \(settings.reminderLeadDays) 天 · \(String(format: "%02d:00", settings.reminderHour))",
                trailing: { AnyView(trailingChev("更改")) }
            ) { showReminderSheet = true }

            SettingsRow(
                icon: "circle.lefthalf.filled",
                title: "主题",
                value: "当前 \(settings.theme.displayName)",
                trailing: { AnyView(themePicker) }
            )

            SettingsRow(
                icon: "dollarsign.circle",
                title: "默认货币",
                value: "\(settings.defaultCurrency.rawValue) · 汇率 \(String(format: "%.2f", settings.usdCnyRate))",
                trailing: { AnyView(trailingChev(settings.defaultCurrency.symbol)) }
            ) { showCurrencySheet = true }

            SettingsRow(
                icon: "bell",
                title: "通知",
                value: settings.notificationsEnabled ? "已开启" : "已关闭",
                trailing: { AnyView(trailingChev("管理")) }
            ) { showNotificationSheet = true }
        }
    }

    private var integrationsGroup: some View {
        SettingsGroup(label: "集成") {
            SettingsRow(
                icon: "bolt.horizontal",
                title: "Webhooks",
                value: "向 Slack / Discord / 自建服务推送事件",
                trailing: { AnyView(trailingChev("管理")) }
            ) { showWebhooks = true }

            SettingsRow(
                icon: "sparkles.rectangle.stack",
                title: "年度分享卡片",
                value: "生成本年度订阅总结，可分享到社交平台",
                trailing: { AnyView(trailingChev("生成")) }
            ) { showYearInReview = true }
        }
    }

    private var dataGroup: some View {
        SettingsGroup(label: "数据") {
            SettingsRow(
                icon: "arrow.down.to.line",
                title: "导出 CSV",
                value: "下载全部 \(subs.count) 条记录",
                trailing: { AnyView(trailingChev(nil)) }
            ) { exportCSV() }

            SettingsRow(
                icon: "icloud",
                title: "iCloud 同步",
                value: "最近一次 · \(lastSyncText)",
                trailing: { AnyView(trailingChev("开启")) }
            )

            SettingsRow(
                icon: "checkmark.square",
                title: "清空示例数据",
                value: "删除所有订阅记录",
                trailing: { AnyView(trailingChev(nil)) }
            ) { clearAll() }
        }
    }

    private var aboutGroup: some View {
        SettingsGroup(label: "关于") {
            SettingsRow(
                icon: "info.circle",
                title: "版本",
                value: "Subscribe 1.0.0 · Build 1",
                trailing: { AnyView(trailingChev(nil)) }
            )
            SettingsRow(
                icon: "bubble.left",
                title: "反馈与建议",
                value: "hi@subscribe.app",
                trailing: { AnyView(trailingChev(nil)) }
            ) {
                if let url = URL(string: "mailto:hi@subscribe.app") { UIApplication.shared.open(url) }
            }
        }
    }

    private var themePicker: some View {
        HStack(spacing: 0) {
            ForEach(ThemePreference.allCases) { t in
                Button {
                    settings.theme = t
                } label: {
                    Text(t == .system ? "自动" : t == .dark ? "深" : "浅")
                        .font(AppFont.geist(11, weight: .medium))
                        .foregroundStyle(settings.theme == t ? palette.bg : palette.ink3)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(settings.theme == t ? palette.ink : Color.clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule().fill(palette.cardHi)
                .overlay(Capsule().strokeBorder(palette.border, lineWidth: 1))
        )
    }

    private func trailingChev(_ text: String?) -> some View {
        HStack(spacing: 6) {
            if let t = text { Text(t).font(AppFont.geist(13)).foregroundStyle(palette.ink3) }
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium)).foregroundStyle(palette.ink3.opacity(0.8))
        }
    }

    private func exportCSV() {
        var lines = ["name,category,price,currency,cycle,next_billing_date,notes"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for s in subs {
            let escaped = s.name.replacingOccurrences(of: "\"", with: "\"\"")
            let noteEsc = s.notes.replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\"\(escaped)\",\(s.category.rawValue),\(s.price),\(s.currency.rawValue),\(s.cycle.rawValue),\(df.string(from: s.nextBillingDate)),\"\(noteEsc)\"")
        }
        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("subscriptions-\(Int(Date().timeIntervalSince1970)).csv")
        try? csv.data(using: .utf8)?.write(to: url)
        exportURL = url
        showExportShare = true
    }

    private func clearAll() {
        for s in subs { context.delete(s) }
        try? context.save()
    }
}

struct SettingsGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(AppFont.geist(10, weight: .medium))
                .kerning(1.4)
                .foregroundStyle(palette.ink3)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.border, lineWidth: 1))
            )
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let trailing: () -> AnyView
    var tap: (() -> Void)? = nil

    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            tap?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.ink2)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7).fill(palette.cardHi)
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(palette.border, lineWidth: 1))
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(AppFont.geist(14, weight: .medium)).foregroundStyle(palette.ink)
                    Text(value).font(AppFont.geist(12)).foregroundStyle(palette.ink3)
                }
                Spacer()
                trailing()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(palette.card)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.border).frame(height: 1)
                .padding(.leading, 56).padding(.trailing, 16)
                .opacity(0.0)
        }
        .background(
            Rectangle().fill(palette.border).frame(height: 1).padding(.leading, 56).padding(.trailing, 16),
            alignment: .top
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var name: String = ""
    @State private var email: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("资料") {
                    TextField("昵称", text: $name)
                    TextField("邮箱", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        settings.userName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "我" : name
                        settings.userEmail = email
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = settings.userName
                email = settings.userEmail
            }
        }
    }
}

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var lead: Int = 3
    @State private var hour: Int = 9

    var body: some View {
        NavigationStack {
            Form {
                Section("提前提醒") {
                    Picker("到期前", selection: $lead) {
                        ForEach([0, 1, 2, 3, 5, 7, 14], id: \.self) { Text(verbatim: "\($0) 天").tag($0) }
                    }
                }
                Section("时间") {
                    Picker("小时", selection: $hour) {
                        ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) }
                    }
                }
            }
            .navigationTitle("提醒设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        settings.reminderLeadDays = lead
                        settings.reminderHour = hour
                        dismiss()
                    }
                }
            }
            .onAppear {
                lead = settings.reminderLeadDays
                hour = settings.reminderHour
            }
        }
    }
}

struct CurrencySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var rateService = ExchangeRateService.shared
    @State private var ccy: CurrencyCode = .cny
    @State private var rate: String = "7.25"

    var body: some View {
        NavigationStack {
            Form {
                Section("默认货币") {
                    CurrencyPickerRow(label: "货币", selection: $ccy)
                }
                Section {
                    RateBadge(
                        rate: settings.usdCnyRate,
                        lastFetched: rateService.lastFetched,
                        source: rateService.lastSource,
                        onRefresh: {
                            await rateService.refresh()
                            rate = String(format: "%.4f", settings.usdCnyRate)
                        }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("实时汇率")
                } footer: {
                    Text("App 启动 + 每 6 小时自动更新；下方可手动覆盖。")
                }
                Section("手动覆盖（USD → CNY）") {
                    TextField("7.25", text: $rate).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("货币")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        settings.defaultCurrency = ccy
                        if let v = Double(rate), v > 0 { settings.usdCnyRate = v }
                        dismiss()
                    }
                }
            }
            .onAppear {
                ccy = settings.defaultCurrency
                rate = String(format: "%.4f", settings.usdCnyRate)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ExchangeRateDidUpdate"))) { _ in
                rate = String(format: "%.4f", AppGroup.usdCnyRate)
                settings.usdCnyRate = AppGroup.usdCnyRate
            }
        }
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var enabled: Bool = true
    @State private var authorized: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("通知") {
                    Toggle("到期提醒推送", isOn: $enabled)
                    if !authorized {
                        Text("提示：系统尚未授权通知，保存时会自动申请权限。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        settings.notificationsEnabled = enabled
                        if enabled {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                enabled = settings.notificationsEnabled
                UNUserNotificationCenter.current().getNotificationSettings { s in
                    DispatchQueue.main.async {
                        authorized = s.authorizationStatus == .authorized
                    }
                }
            }
        }
    }
}
