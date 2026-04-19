import SwiftUI
import SwiftData

struct WebhookSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WebhookEndpoint.createdAt, order: .reverse) private var endpoints: [WebhookEndpoint]

    @State private var editingEndpoint: WebhookEndpoint?
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if endpoints.isEmpty {
                        Text("还没有 Webhook。点右上 + 添加，或先看下下面的事件说明。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(endpoints) { endpoint in
                            Button {
                                editingEndpoint = endpoint
                            } label: {
                                row(for: endpoint)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                } header: {
                    Text("已配置")
                } footer: {
                    Text("URL 必须 HTTPS。失败自动重试 3 次（1s/4s 退避）。")
                }

                Section {
                    ForEach(WebhookEvent.allCases) { e in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(e.rawValue).font(.system(.callout, design: .monospaced)).foregroundStyle(.primary)
                                Spacer()
                                Text(e.displayName).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(e.brief).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("支持的事件")
                } footer: {
                    Text("App 在前台或冷启动时扫描即将到期的订阅；后台触发依赖系统调度，不保证实时。每个事件每天每订阅去重一次。")
                }
            }
            .navigationTitle("Webhooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { WebhookEditView(editing: nil) }
            .sheet(item: $editingEndpoint) { ep in WebhookEditView(editing: ep) }
        }
    }

    @ViewBuilder
    private func row(for endpoint: WebhookEndpoint) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(endpoint.enabled ? .green : .gray)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(endpoint.name.isEmpty ? "未命名" : endpoint.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(endpoint.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(endpoint.lastStatusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor(for: endpoint))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func statusColor(for endpoint: WebhookEndpoint) -> Color {
        if endpoint.lastAttemptAt == nil { return .secondary }
        if !endpoint.lastErrorMessage.isEmpty { return .red }
        if (200..<300).contains(endpoint.lastStatusCode) { return .green }
        return .orange
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            context.delete(endpoints[i])
        }
        try? context.save()
    }
}
