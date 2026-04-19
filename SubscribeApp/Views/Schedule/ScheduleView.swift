import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var settings: AppSettings
    @Query private var subs: [Subscription]

    @State private var anchor: Date = {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: DateComponents(year: c.year, month: c.month, day: 1)) ?? Date()
    }()
    @State private var selected: Date = Calendar(identifier: .gregorian).startOfDay(for: Date())
    @State private var editingSub: Subscription?

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1
        return c
    }

    private var gridDays: [Date] {
        let comps = cal.dateComponents([.year, .month], from: anchor)
        guard let first = cal.date(from: comps) else { return [] }
        let startDow = cal.component(.weekday, from: first) - 1
        guard let gridStart = cal.date(byAdding: .day, value: -startDow, to: first) else { return [] }
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var eventsByDate: [String: [Subscription]] {
        var map: [String: [Subscription]] = [:]
        for s in subs {
            let key = dateKey(s.nextBillingDate)
            map[key, default: []].append(s)
        }
        return map
    }

    private func dateKey(_ d: Date) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func sameDay(_ a: Date, _ b: Date) -> Bool {
        cal.isDate(a, inSameDayAs: b)
    }

    private var selEvents: [Subscription] {
        eventsByDate[dateKey(selected)] ?? []
    }

    private var selTotal: Double {
        selEvents.reduce(0) { $0 + $1.priceInCNY(usdRate: settings.usdCnyRate) }
    }

    private var monthEvents: [Subscription] {
        let m = cal.component(.month, from: anchor)
        let y = cal.component(.year, from: anchor)
        return subs
            .filter {
                let c = cal.dateComponents([.year, .month], from: $0.nextBillingDate)
                return c.year == y && c.month == m
            }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TopBar(eyebrow: "SCHEDULE · UPCOMING", avatarText: String(settings.userName.prefix(1)).uppercased())
                BigTitle(text: "日程")

                if subs.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.badge.exclamationmark",
                        title: "日历是空的",
                        message: "添加订阅后这里会显示扣款日历，每天的支出一目了然。"
                    )
                    .padding(.top, 30)
                } else {
                    calendarNav.padding(.horizontal, 24).padding(.top, 14)
                    weekHead.padding(.horizontal, 24).padding(.top, 16)
                    calGrid.padding(.horizontal, 20).padding(.top, 2)

                    dayDetailCard.padding(.horizontal, 24).padding(.top, 20)

                    SectionHead("本月全部", meta: "\(monthEvents.count) EVENTS")

                    monthList
                }
            }
        }
        .sheet(item: $editingSub) { sub in AddEditSubscriptionView(editing: sub) }
    }

    private var calendarNav: some View {
        HStack {
            Text(Fmt.monthTitle(anchor))
                .font(AppFont.geist(20, weight: .semibold))
                .kerning(-0.4)
                .foregroundStyle(palette.ink)
            Spacer()
            HStack(spacing: 6) {
                navBtn(systemName: "chevron.left") { shiftMonth(-1) }
                navBtn(systemName: "chevron.right") { shiftMonth(1) }
            }
        }
    }

    private func navBtn(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.ink2)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(palette.card)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.border, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    private var weekHead: some View {
        HStack(spacing: 2) {
            ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                Text(d)
                    .font(AppFont.geist(10, weight: .medium))
                    .kerning(1.2)
                    .foregroundStyle(palette.ink3)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    private var calGrid: some View {
        let month = cal.component(.month, from: anchor)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, d in
                dayCell(date: d, inMonth: cal.component(.month, from: d) == month)
            }
        }
    }

    private func dayCell(date: Date, inMonth: Bool) -> some View {
        let evts = eventsByDate[dateKey(date)] ?? []
        let isToday = sameDay(date, Date())
        let isSel = sameDay(date, selected)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selected = date }
        } label: {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Group {
                    if isToday {
                        Text("\(cal.component(.day, from: date))")
                            .font(AppFont.geist(13, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(palette.bg)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(palette.ink))
                    } else {
                        Text("\(cal.component(.day, from: date))")
                            .font(AppFont.geist(13, weight: evts.isEmpty ? .medium : .semibold))
                            .monospacedDigit()
                            .foregroundStyle(palette.ink)
                    }
                }
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    ForEach(evts.prefix(3), id: \.persistentModelID) { s in
                        Circle().fill(s.category.accentColor).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
                .padding(.bottom, 5)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1/1.05, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSel ? palette.card : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(isSel ? palette.ink : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(inMonth ? 1 : 0.25)
        }
        .buttonStyle(.plain)
    }

    private var dayDetailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(Fmt.longDate(selected))
                    .font(AppFont.geist(14, weight: .semibold))
                    .kerning(-0.15)
                    .foregroundStyle(palette.ink)
                Spacer()
                Text(selEvents.isEmpty ? "NO EVENT" : "\(selEvents.count) · ¥\(Int(selTotal.rounded()))")
                    .font(AppFont.geist(11, weight: .medium))
                    .kerning(1.0)
                    .foregroundStyle(palette.ink3)
            }

            if selEvents.isEmpty {
                Text("这一天没有扣款")
                    .font(AppFont.geist(13))
                    .foregroundStyle(palette.ink3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(selEvents.enumerated()), id: \.element.persistentModelID) { idx, s in
                        if idx > 0 { Rectangle().fill(palette.border).frame(height: 1) }
                        HStack(spacing: 11) {
                            BrandIcon(sub: s, size: 28)
                            Text(s.name).font(AppFont.geist(13, weight: .medium)).foregroundStyle(palette.ink)
                            Spacer()
                            Text(Fmt.money(s.price, s.currency))
                                .font(AppFont.geist(14, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(palette.ink)
                        }
                        .padding(.vertical, 9)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.card)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.border, lineWidth: 1))
        )
    }

    private var monthList: some View {
        VStack(spacing: 0) {
            ForEach(Array(monthEvents.enumerated()), id: \.element.persistentModelID) { idx, s in
                Button {
                    editingSub = s
                } label: {
                    SubscriptionRow(sub: s, showDivider: idx > 0)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("跳到这一天") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selected = cal.startOfDay(for: s.nextBillingDate)
                            anchor = cal.date(from: cal.dateComponents([.year, .month], from: s.nextBillingDate)) ?? anchor
                        }
                    }
                    Button("编辑") { editingSub = s }
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: anchor) {
            withAnimation(.easeInOut(duration: 0.2)) { anchor = d }
        }
    }
}
