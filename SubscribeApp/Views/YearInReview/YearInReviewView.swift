import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// A `Transferable` PNG wrapper so `ShareLink` can hand the rendered card off
/// to any system share target (Photos, Messages, Instagram, AirDrop…).
struct ShareablePNG: Transferable {
    let data: Data
    let suggestedName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.data
        }
        .suggestedFileName { $0.suggestedName }
    }
}

/// Interactive sheet that shows a scaled preview of `YearInReviewCard` and
/// exposes a `ShareLink` to share the rasterized PNG.
struct YearInReviewView: View {
    let year: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @EnvironmentObject private var settings: AppSettings

    @Query private var subs: [Subscription]

    @State private var sharePayload: ShareablePNG?
    @State private var isRendering = false

    init(year: Int) {
        self.year = year
    }

    private var usdCnyRate: Double { AppGroup.usdCnyRate }

    private var card: YearInReviewCard {
        YearInReviewCard(year: year, subs: subs, usdCnyRate: usdCnyRate)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let availableWidth = max(220, geo.size.width - 32)
                let scale = availableWidth / 1080.0

                ScrollView {
                    VStack(spacing: 24) {
                        cardPreview(scale: scale)
                            .padding(.top, 20)

                        infoBlock
                            .padding(.horizontal, 20)

                        shareButton
                            .padding(.horizontal, 20)

                        Spacer(minLength: 24)
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(palette.bg.ignoresSafeArea())
            }
            .navigationTitle("年度分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(palette.amber)
                }
            }
            .task {
                // Pre-render the PNG as soon as the sheet appears so ShareLink
                // is live on first tap (otherwise user needs two taps).
                await renderShareImageAsync()
            }
            .onChange(of: subs.count) { _, _ in
                // Subscription list updated mid-view → invalidate cached PNG.
                sharePayload = nil
                Task { await renderShareImageAsync() }
            }
        }
    }

    // MARK: - Sections

    private func cardPreview(scale: CGFloat) -> some View {
        card
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: 1080 * scale, height: 1920 * scale, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(String(year)) 年 · 共 \(subs.count) 项订阅")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.ink)
            Text("点击下方按钮可将卡片以 1080 × 1920 的图片分享到任意 App。")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(palette.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var shareButton: some View {
        if let payload = sharePayload {
            // Use SwiftUI Image preview from the rendered PNG so iOS shows
            // a real thumbnail in the share sheet header.
            let previewImage = UIImage(data: payload.data).map(Image.init(uiImage:))
                ?? Image(systemName: "square.and.arrow.up")
            ShareLink(
                item: payload,
                preview: SharePreview(
                    "Subtally \(String(year)) 年度总结",
                    image: previewImage
                )
            ) {
                shareLabel(title: "分享卡片")
            }
            // Provide a secondary "保存到相册" button next to share for users
            // who just want the PNG file in their library.
            Button {
                saveToPhotos(payload.data)
            } label: {
                Text("保存到相册")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        } else {
            // Render in progress on first appear — show spinner placeholder.
            shareLabel(
                title: isRendering ? "正在生成卡片…" : "准备中…",
                showSpinner: true
            )
        }
    }

    private func saveToPhotos(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func shareLabel(title: String, showSpinner: Bool = false) -> some View {
        HStack(spacing: 10) {
            if showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(palette.bg)
            } else {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .bold))
            }
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
        }
        .foregroundStyle(palette.bg)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.amber)
        )
    }

    // MARK: - Rendering

    @MainActor
    private func renderShareImageAsync() async {
        guard sharePayload == nil, !isRendering else { return }
        isRendering = true
        // Yield once so the sheet has time to draw its UI before we hammer
        // the renderer (avoids the spinner being skipped on fast hardware).
        await Task.yield()

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0  // 1080 × 1920 native
        renderer.proposedSize = .init(width: 1080, height: 1920)

        if let ui = renderer.uiImage, let data = ui.pngData() {
            sharePayload = ShareablePNG(
                data: data,
                suggestedName: "Subtally-\(year)-年度总结.png"
            )
        }
        isRendering = false
    }
}
