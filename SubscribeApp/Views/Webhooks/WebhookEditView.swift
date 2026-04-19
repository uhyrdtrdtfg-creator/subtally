import SwiftUI
import SwiftData

struct WebhookEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    let editing: WebhookEndpoint?

    @State private var name: String = ""
    @State private var url: String = ""
    @State private var enabled: Bool = true
    @State private var secretText: String = ""
    @State private var events: Set<WebhookEvent> = Set(WebhookEvent.allCases)

    @State private var useCustomBody: Bool = false
    @State private var bodyTemplate: String = ""
    @State private var contentType: String = "application/json; charset=utf-8"
    @State private var httpMethod: WebhookHTTPMethod = .post
    @State private var customHeadersRaw: String = ""

    @State private var showVariableHelp = false
    @State private var showPreview = false
    @State private var testing = false
    @State private var testResult: String?
    @State private var insertedToast: String?

    @StateObject private var bodyEditorController = CodeTextEditorController()

    init(editing: WebhookEndpoint?) {
        self.editing = editing
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                customRequestSection
                if useCustomBody { templateSection }
                signatureSection
                eventsSection
                testSection
                if editing != nil {
                    Section {
                        Button("删除", role: .destructive) { deleteEndpoint() }
                    }
                }
            }
            .navigationTitle(editing == nil ? "新建 Webhook" : "编辑 Webhook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(!canSave)
                }
            }
            .sheet(isPresented: $showVariableHelp) { variableHelpSheet }
            .sheet(isPresented: $showPreview) { previewSheet }
            .onAppear(perform: load)
        }
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section {
            TextField("名称（如 'Slack 通知'）", text: $name)
            TextField("https://...", text: $url)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            Toggle("启用", isOn: $enabled)
        } header: {
            Text("基本")
        } footer: {
            Text("URL 必须 https://（开发可临时 http://）。")
        }
    }

    private var customRequestSection: some View {
        Section {
            Picker("方法", selection: $httpMethod) {
                ForEach(WebhookHTTPMethod.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            Toggle("使用自定义 body", isOn: $useCustomBody)

            if useCustomBody {
                TextField("Content-Type", text: $contentType)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
            }
        } header: {
            Text("请求格式")
        } footer: {
            Text(useCustomBody
                 ? "关掉就用 App 内置 JSON 结构（含 subscription DTO + delivery_id）。"
                 : "默认会发 App 自带的标准 JSON。开关开启后可以自由改 body 模板，例如对接 Slack / Discord / Bark。")
        }
    }

    private var templateSection: some View {
        Section {
            Menu {
                ForEach(WebhookTemplate.presets) { p in
                    Button(p.name) { applyPreset(p) }
                }
            } label: {
                Label("插入预设模板", systemImage: "square.and.arrow.down")
            }

            HStack {
                Button { showVariableHelp = true } label: {
                    Label("可用变量", systemImage: "list.bullet.rectangle")
                }
                Spacer()
                Button { showPreview = true } label: {
                    Label("预览", systemImage: "eye")
                }
            }
            .buttonStyle(.borderless)

            ZStack(alignment: .topLeading) {
                if bodyTemplate.isEmpty {
                    Text("Body 模板，使用 {{subscription.name}} 这样的占位符…")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                CodeTextEditor(text: $bodyTemplate, controller: bodyEditorController)
                    .frame(minHeight: 200)
            }

            customHeadersField
        } header: {
            Text("Body 模板")
        } footer: {
            Text("App 渲染模板后再发送。常见占位符见「可用变量」。")
        }
    }

    private var customHeadersField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("自定义请求头（可选）").font(.footnote).foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if customHeadersRaw.isEmpty {
                    Text("Authorization: Bearer xxx\nX-Source: SubscribeApp")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                CodeTextEditor(text: $customHeadersRaw)
                    .frame(minHeight: 70)
            }
        }
    }

    private var signatureSection: some View {
        Section {
            SecureField("可选 · HMAC-SHA256 共享密钥", text: $secretText)
        } header: {
            Text("签名")
        } footer: {
            Text("如果填写，App 会对最终发送的 body 用 HMAC-SHA256 签名，写在 X-Webhook-Signature 头里：sha256=<hex>")
        }
    }

    private var eventsSection: some View {
        Section {
            ForEach(WebhookEvent.allCases) { e in
                Toggle(isOn: Binding(
                    get: { events.contains(e) },
                    set: { on in
                        if on { events.insert(e) } else { events.remove(e) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.displayName)
                        Text(e.rawValue).font(.caption2).foregroundStyle(.secondary).monospaced()
                    }
                }
            }
        } header: {
            Text("订阅事件")
        }
    }

    private var testSection: some View {
        Section {
            Button {
                Task { await runTest() }
            } label: {
                HStack {
                    Image(systemName: "paperplane")
                    Text(testing ? "发送中…" : "发送测试请求")
                    Spacer()
                    if testing { ProgressView() }
                }
            }
            .disabled(testing || !canSave)
            if let r = testResult {
                Text(r)
                    .font(.footnote)
                    .foregroundStyle(r.hasPrefix("成功") ? .green : .red)
            }
        } footer: {
            Text("测试会用模拟数据触发 subscription.added，按当前模板发请求。")
        }
    }

    // MARK: - Help / Preview sheets

    private var variableHelpSheet: some View {
        NavigationStack {
            List {
                Section {
                    Label("点击任一变量直接插入到 Body 模板光标位置", systemImage: "hand.tap")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("事件 / 元信息") {
                    helpRow("event", "如 bill.upcoming")
                    helpRow("event_display", "如 扣款临近")
                    helpRow("timestamp", "ISO8601 时间戳")
                    helpRow("delivery_id", "本次投递 UUID")
                    helpRow("app", "Subtally iOS")
                }
                Section("订阅字段") {
                    helpRow("subscription.id", "稳定 UUID")
                    helpRow("subscription.name", "名称（已 JSON 转义）")
                    helpRow("subscription.category", "VIDEO/MUSIC/CLOUD/AI/WORK")
                    helpRow("subscription.price", "原始数字")
                    helpRow("subscription.price_formatted", "如 ¥68 或 $20")
                    helpRow("subscription.currency", "CNY/USD")
                    helpRow("subscription.cycle", "month/year")
                    helpRow("subscription.cycle_display", "按月/年度")
                    helpRow("subscription.next_billing_date", "ISO8601")
                    helpRow("subscription.next_billing_date_short", "如 4月26日")
                    helpRow("subscription.days_until_next", "整数")
                    helpRow("subscription.is_free_trial", "true/false")
                    helpRow("subscription.trial_end_date", "ISO8601 或空")
                    helpRow("subscription.trial_days_remaining", "整数 或空")
                    helpRow("subscription.notes", "备注（已 JSON 转义）")
                    helpRow("subscription.price_cny", "按汇率换算到 CNY")
                    helpRow("subscription.monthly_cost_cny", "归一化到月")
                }
            }
            .navigationTitle("可用变量")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showVariableHelp = false }
                }
            }
            .overlay(alignment: .top) {
                if let t = insertedToast {
                    InsertToast(text: t)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func helpRow(_ key: String, _ desc: String) -> some View {
        Button {
            insertVariable(key)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("{{\(key)}}")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.primary)
                    Text(desc).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
                    .font(.body)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func insertVariable(_ key: String) {
        let token = "{{\(key)}}"
        bodyEditorController.insert(token)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.18)) {
            insertedToast = token
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            withAnimation(.easeIn(duration: 0.2)) {
                insertedToast = nil
            }
        }
    }

    private var previewSheet: some View {
        let transient = transientEndpoint()
        let preview = WebhookDispatcher.shared.renderPreview(for: transient, usdCnyRate: settings.usdCnyRate)
        let resolved = previewVariables()
        return NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        BrandIcon(slug: "netflix", colorHex: "E50914", fallbackLetter: "N", size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Netflix · 扣款临近").font(.subheadline.weight(.semibold))
                            Text("¥68 · 4月21日（3 天后）")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("样例数据")
                } footer: {
                    Text("以下用 Netflix 的 bill.upcoming 模拟，看下你的模板会渲染出什么。")
                }

                Section {
                    ForEach(resolved, id: \.key) { item in
                        Button {
                            insertVariable(item.key)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label).font(.callout).foregroundStyle(.primary)
                                    Text("{{\(item.key)}}").font(.caption2).monospaced().foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Text(item.value.isEmpty ? "（空）" : item.value)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.tint)
                                    .font(.callout)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("变量解析（中文）· 点击插入")
                } footer: {
                    Text("想用中文标签显示事件，点击 event_display 即可插入 {{event_display}}。")
                }

                Section {
                    Text(preview.isEmpty ? "(empty)" : preview)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                } header: {
                    Text("最终发送 Body")
                } footer: {
                    Text("HMAC 签名（如有）会基于这段最终 body 计算。")
                }
            }
            .navigationTitle("Body 预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showPreview = false }
                }
            }
            .overlay(alignment: .top) {
                if let t = insertedToast {
                    InsertToast(text: t)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func previewVariables() -> [(key: String, label: String, value: String)] {
        let cal = Calendar(identifier: .gregorian)
        let dummy = Subscription(
            name: "Netflix", category: .video, price: 68, currency: .cny, cycle: .month,
            nextBillingDate: cal.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            slug: "netflix", brandColorHex: "E50914", fallbackLetter: "N"
        )
        let vars = WebhookTemplate.variables(
            event: .billUpcoming, sub: dummy,
            timestamp: Date(), deliveryID: UUID().uuidString,
            usdCnyRate: settings.usdCnyRate
        )
        let labels: [(String, String)] = [
            ("event", "事件代码"),
            ("event_display", "事件名（中文）"),
            ("timestamp", "时间戳 (ISO8601)"),
            ("delivery_id", "投递 ID"),
            ("app", "App 名"),
            ("subscription.id", "订阅 ID"),
            ("subscription.name", "订阅名"),
            ("subscription.category", "分类代码"),
            ("subscription.price", "金额（数字）"),
            ("subscription.price_formatted", "金额（带符号）"),
            ("subscription.currency", "币种"),
            ("subscription.cycle", "周期代码"),
            ("subscription.cycle_display", "周期（中文）"),
            ("subscription.next_billing_date", "下次扣款 ISO"),
            ("subscription.next_billing_date_short", "下次扣款（短）"),
            ("subscription.days_until_next", "剩余天数"),
            ("subscription.is_free_trial", "是否试用"),
            ("subscription.trial_end_date", "试用结束日期"),
            ("subscription.trial_days_remaining", "试用剩余天数"),
            ("subscription.notes", "备注"),
            ("subscription.price_cny", "金额（CNY）"),
            ("subscription.monthly_cost_cny", "月化金额 (CNY)"),
        ]
        return labels.map { (key: $0.0, label: $0.1, value: vars[$0.0] ?? "") }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        URL(string: url.trimmingCharacters(in: .whitespaces))?.scheme != nil &&
        !events.isEmpty
    }

    private func applyPreset(_ p: WebhookTemplate.Preset) {
        bodyTemplate = p.body
        contentType = p.contentType
        httpMethod = p.method
        useCustomBody = !p.body.isEmpty
    }

    private func load() {
        guard let e = editing else { return }
        name = e.name
        url = e.url
        enabled = e.enabled
        secretText = e.secretText
        events = e.subscribedEvents
        useCustomBody = e.useCustomBody
        bodyTemplate = e.bodyTemplate
        contentType = e.contentType
        httpMethod = e.httpMethod
        customHeadersRaw = e.customHeadersRaw
    }

    private func transientEndpoint() -> WebhookEndpoint {
        let endpoint = WebhookEndpoint(
            name: name,
            url: url.trimmingCharacters(in: .whitespaces),
            secretText: secretText,
            events: events
        )
        endpoint.enabled = true
        endpoint.useCustomBody = useCustomBody
        endpoint.bodyTemplate = bodyTemplate.normalizingSmartPunctuation()
        endpoint.contentType = contentType.normalizingSmartPunctuation()
        endpoint.httpMethod = httpMethod
        endpoint.customHeadersRaw = customHeadersRaw.normalizingSmartPunctuation()
        return endpoint
    }

    private func save() {
        let trimmedURL = url.trimmingCharacters(in: .whitespaces)
        let cleanedBody = bodyTemplate.normalizingSmartPunctuation()
        let cleanedHeaders = customHeadersRaw.normalizingSmartPunctuation()
        let cleanedContentType = contentType.normalizingSmartPunctuation()

        if let e = editing {
            e.name = name.trimmingCharacters(in: .whitespaces)
            e.url = trimmedURL
            e.enabled = enabled
            e.secretText = secretText
            e.subscribedEvents = events
            e.useCustomBody = useCustomBody
            e.bodyTemplate = cleanedBody
            e.contentType = cleanedContentType
            e.httpMethod = httpMethod
            e.customHeadersRaw = cleanedHeaders
        } else {
            let endpoint = WebhookEndpoint(
                name: name.trimmingCharacters(in: .whitespaces),
                url: trimmedURL,
                secretText: secretText,
                events: events
            )
            endpoint.enabled = enabled
            endpoint.useCustomBody = useCustomBody
            endpoint.bodyTemplate = cleanedBody
            endpoint.contentType = cleanedContentType
            endpoint.httpMethod = httpMethod
            endpoint.customHeadersRaw = cleanedHeaders
            context.insert(endpoint)
        }
        try? context.save()
        dismiss()
    }

    private func deleteEndpoint() {
        if let e = editing {
            context.delete(e)
            try? context.save()
        }
        dismiss()
    }

    private func runTest() async {
        testing = true
        testResult = nil
        let result = await WebhookDispatcher.shared.sendTest(
            endpoint: transientEndpoint(),
            context: context,
            usdCnyRate: settings.usdCnyRate
        )
        testResult = result
        testing = false
    }
}

private struct InsertToast: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
            Text("已插入 \(text)")
                .font(.footnote.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.78), in: Capsule())
    }
}
