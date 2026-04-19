import SwiftUI
import SwiftData

struct AddEditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    let editing: Subscription?

    @State private var name: String = ""
    @State private var category: SubscriptionCategory = .work
    @State private var price: String = ""
    @State private var currency: CurrencyCode = .cny
    @State private var cycle: BillingCycle = .month
    @State private var nextDate: Date = Date()
    @State private var slug: String = ""
    @State private var colorHex: String = "888888"
    @State private var letter: String = "•"
    @State private var notes: String = ""
    @State private var isFreeTrial: Bool = false
    @State private var trialEndDate: Date = Calendar(identifier: .gregorian).date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var totalShares: Int = 1
    @State private var mineShares: Int = 1
    @State private var sharedNote: String = ""

    @State private var showTemplatePicker = false
    @State private var showReceiptScan = false
    @State private var showPriceHistory = false
    @State private var dupConfirm: DupCandidate?

    struct DupCandidate: Identifiable {
        let id = UUID()
        let existing: Subscription
    }

    init(editing: Subscription? = nil) {
        self.editing = editing
    }

    var body: some View {
        NavigationStack {
            Form {
                if editing == nil {
                    Section {
                        Button {
                            showTemplatePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                Text("从模板快速添加")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                            }
                        }
                        Button {
                            showReceiptScan = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                Text("扫描支付凭证自动填充")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                            }
                        }
                    }
                }

                Section("基本信息") {
                    TextField("名称", text: $name)
                    Picker("分类", selection: $category) {
                        ForEach(SubscriptionCategory.allCases) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                }

                Section("价格") {
                    TextField("金额", text: $price).keyboardType(.decimalPad)
                    CurrencyPickerRow(label: "货币", selection: $currency)
                    Picker("计费周期", selection: $cycle) {
                        ForEach(BillingCycle.allCases) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("下次扣款") {
                    DatePicker("日期", selection: $nextDate, displayedComponents: [.date])
                }

                Section {
                    Toggle("免费试用中", isOn: $isFreeTrial)
                    if isFreeTrial {
                        DatePicker("试用结束日期", selection: $trialEndDate, displayedComponents: [.date])
                    }
                } header: {
                    Text("免费试用")
                } footer: {
                    if isFreeTrial {
                        Text("App 会在试用结束前 2 天和当日各推送一次强提醒")
                    }
                }

                SharedBillingSection(
                    totalShares: $totalShares,
                    mineShares: $mineShares,
                    note: $sharedNote,
                    totalPriceText: previewPriceText
                )

                if let editingSub = editing {
                    Section {
                        Button {
                            showPriceHistory = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("查看价格历史")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                            }
                        }
                        CancellationButton(sub: editingSub)
                    }
                }

                Section("品牌标识") {
                    TextField("Simple Icons slug（可留空）", text: $slug).autocapitalization(.none)
                    TextField("颜色 HEX（不带 #）", text: $colorHex).autocapitalization(.none)
                    TextField("首字母", text: $letter)
                }

                Section("备注") {
                    TextField("选填", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if editing != nil {
                    Section {
                        Button("删除订阅", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(editing == nil ? "新建订阅" : "编辑订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.disabled(!canSave) }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView { t in applyTemplate(t) }
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanView(
                    onExtracted: { info in
                        applyReceipt(info)
                        showReceiptScan = false
                    },
                    onCancel: { showReceiptScan = false }
                )
            }
            .sheet(isPresented: $showPriceHistory) {
                if let e = editing {
                    PriceHistoryView(subID: e.stableID, subName: e.name)
                }
            }
            .alert(
                "可能重复",
                isPresented: Binding(
                    get: { dupConfirm != nil },
                    set: { if !$0 { dupConfirm = nil } }
                ),
                presenting: dupConfirm
            ) { dup in
                Button("仍然新建") {
                    dupConfirm = nil
                    persist()
                }
                Button("取消", role: .cancel) { dupConfirm = nil }
            } message: { dup in
                Text("已经有一条「\(dup.existing.name)」（\(Fmt.shortDate(dup.existing.nextBillingDate)) · \(dup.existing.cycle.displayName)）。要继续新建吗？")
            }
            .onAppear(perform: load)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(price) != nil
    }

    private func applyTemplate(_ t: SubscriptionTemplate) {
        name = t.name
        category = t.category
        price = formatted(t.suggestedPrice)
        currency = t.suggestedCurrency
        cycle = t.suggestedCycle
        slug = t.slug
        colorHex = t.colorHex
        letter = t.letter.isEmpty ? String(t.name.prefix(1)) : t.letter
    }

    private func applyReceipt(_ info: ReceiptInfo) {
        if let m = info.merchant, !m.isEmpty {
            name = m
            // Try to match against our template catalog for better branding
            if let match = SubscriptionTemplate.all.first(where: { $0.name.lowercased() == m.lowercased() }) {
                category = match.category
                slug = match.slug
                colorHex = match.colorHex
                letter = match.letter.isEmpty ? String(m.prefix(1)) : match.letter
            } else if letter.trimmingCharacters(in: .whitespaces).isEmpty || letter == "•" {
                letter = String(m.prefix(1))
            }
        }
        if let amt = info.amount {
            price = formatted(amt)
        }
        if let c = info.currency {
            currency = c
        }
        if let d = info.date {
            // OCR date is typically the charge date; push next billing forward one cycle
            let cal = Calendar(identifier: .gregorian)
            let next = cal.date(byAdding: cycle == .year ? .year : .month, value: 1, to: d) ?? d
            nextDate = next
        }
    }

    private func formatted(_ v: Double) -> String {
        abs(v - v.rounded()) < 0.01 ? "\(Int(v))" : String(format: "%.2f", v)
    }

    private func load() {
        if let e = editing {
            name = e.name
            category = e.category
            price = String(e.price)
            currency = e.currency
            cycle = e.cycle
            nextDate = e.nextBillingDate
            slug = e.slug
            colorHex = e.brandColorHex
            letter = e.fallbackLetter
            notes = e.notes
            isFreeTrial = e.isFreeTrial
            if let end = e.trialEndDate { trialEndDate = end }
            totalShares = e.totalShares
            mineShares = e.mineShares
            sharedNote = e.sharedNote
        } else {
            currency = settings.defaultCurrency
            nextDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: 30, to: Date()) ?? Date()
        }
    }

    private var previewPriceText: String {
        let v = Double(price) ?? 0
        return Fmt.money(v, currency)
    }

    private func save() {
        if editing == nil, let existing = findDuplicate() {
            dupConfirm = DupCandidate(existing: existing)
            return
        }
        persist()
    }

    private func findDuplicate() -> Subscription? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedName.isEmpty else { return nil }
        let descriptor = FetchDescriptor<Subscription>()
        let existing = (try? context.fetch(descriptor)) ?? []
        return existing.first { $0.name.trimmingCharacters(in: .whitespaces).lowercased() == trimmedName }
    }

    private func persist() {
        let priceVal = Double(price) ?? 0
        let cleanedLetter = letter.trimmingCharacters(in: .whitespaces).isEmpty ? String(name.prefix(1)) : letter
        let cleanedColor = colorHex.trimmingCharacters(in: .whitespaces).isEmpty ? "888888" : colorHex

        let event: WebhookEvent
        let target: Subscription
        var priceDidChange = false
        if let e = editing {
            // Record price change BEFORE mutating
            if e.price != priceVal || e.currency != currency {
                PriceChangeRecorder.record(
                    sub: e,
                    oldPrice: e.price,
                    newPrice: priceVal,
                    oldCurrency: e.currency,
                    newCurrency: currency,
                    context: context
                )
                priceDidChange = true
            }
            e.name = name
            e.category = category
            e.price = priceVal
            e.currency = currency
            e.cycle = cycle
            e.nextBillingDate = nextDate
            e.slug = slug
            e.brandColorHex = cleanedColor
            e.fallbackLetter = cleanedLetter
            e.notes = notes
            e.isFreeTrial = isFreeTrial
            e.trialEndDate = isFreeTrial ? trialEndDate : nil
            e.totalShares = max(1, totalShares)
            e.mineShares = max(1, min(mineShares, max(1, totalShares)))
            e.sharedNote = sharedNote
            event = .subscriptionUpdated
            target = e
        } else {
            let sub = Subscription(
                name: name,
                category: category,
                price: priceVal,
                currency: currency,
                cycle: cycle,
                nextBillingDate: nextDate,
                slug: slug,
                brandColorHex: cleanedColor,
                fallbackLetter: cleanedLetter,
                notes: notes,
                isFreeTrial: isFreeTrial,
                trialEndDate: isFreeTrial ? trialEndDate : nil,
                totalShares: max(1, totalShares),
                mineShares: max(1, min(mineShares, max(1, totalShares))),
                sharedNote: sharedNote
            )
            context.insert(sub)
            event = .subscriptionAdded
            target = sub
        }
        try? context.save()
        let snapshotID = target.stableID
        let firePriceChanged = priceDidChange
        Task { @MainActor in
            await NotificationScheduler.shared.scheduleAll(context: context, settings: settings)
            await WebhookDispatcher.shared.fire(event: event, sub: target, context: context, usdCnyRate: settings.usdCnyRate)
            if firePriceChanged {
                await WebhookDispatcher.shared.fire(event: .priceChanged, sub: target, context: context, usdCnyRate: settings.usdCnyRate)
            }
            if isFreeTrial {
                await TrialActivityManager.shared.startOrUpdate(for: target)
            } else {
                await TrialActivityManager.shared.end(subID: snapshotID)
            }
            WidgetReloader.reload()
        }
        dismiss()
    }

    private func delete() {
        if let e = editing {
            let snapshot = e
            let snapshotID = e.stableID
            Task { @MainActor in
                await WebhookDispatcher.shared.fire(event: .subscriptionDeleted, sub: snapshot, context: context, usdCnyRate: settings.usdCnyRate)
                await TrialActivityManager.shared.end(subID: snapshotID)
            }
            context.delete(e)
            try? context.save()
            Task { @MainActor in
                await NotificationScheduler.shared.scheduleAll(context: context, settings: settings)
                WidgetReloader.reload()
            }
        }
        dismiss()
    }
}
