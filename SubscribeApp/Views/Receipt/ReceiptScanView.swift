import SwiftUI
import PhotosUI
import Vision
import UIKit

struct ReceiptScanView: View {
    enum ImageSource: Hashable {
        case photos
        case camera
    }

    let onExtracted: (ReceiptInfo) -> Void
    let onCancel: () -> Void

    // Source selection
    @State private var source: ImageSource = .photos

    // Image state
    @State private var pickedItem: PhotosPickerItem?
    @State private var image: UIImage?

    // Camera sheet
    @State private var showCamera = false

    // OCR state
    @State private var isRecognizing = false
    @State private var rawText: String = ""

    // Editable fields
    @State private var merchant: String = ""
    @State private var amountText: String = ""
    @State private var currency: CurrencyCode = .cny
    @State private var date: Date = Date()

    // Permission alert
    @State private var showPermissionAlert = false
    @State private var permissionMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("source", selection: $source) {
                    Text("从相册").tag(ImageSource.photos)
                    Text("拍照").tag(ImageSource.camera)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if image == nil {
                    emptyPicker
                } else {
                    resultView
                }

                Spacer(minLength: 0)

                Button {
                    submit()
                } label: {
                    Text("用这些字段新建订阅")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .navigationTitle("扫描支付凭证")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { onCancel() }
                }
            }
            .onChange(of: source) { _, newValue in
                if newValue == .camera {
                    requestCameraIfNeeded()
                }
            }
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPickedItem(newItem) }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { uiImage in
                    showCamera = false
                    if let uiImage { onImage(uiImage) }
                } onCancel: {
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .alert("无法访问", isPresented: $showPermissionAlert) {
                Button("取消", role: .cancel) {}
                Button("打开设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(permissionMessage)
            }
        }
    }

    // MARK: - Subviews

    private var emptyPicker: some View {
        Group {
            switch source {
            case .photos:
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    pickerLabel(title: "选择凭证截图", system: "photo.on.rectangle.angled")
                }
            case .camera:
                Button {
                    requestCameraIfNeeded()
                } label: {
                    pickerLabel(title: "选择凭证截图", system: "camera")
                }
            }
        }
        .padding(.horizontal)
    }

    private func pickerLabel(title: String, system: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: system)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(.secondary.opacity(0.4))
        )
    }

    private var resultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                }

                if isRecognizing {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("识别中…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Form {
                    Section("提取字段") {
                        TextField("商户", text: $merchant)
                        TextField("金额", text: $amountText)
                            .keyboardType(.decimalPad)
                        Picker("币种", selection: $currency) {
                            ForEach(CurrencyCode.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        DatePicker("日期", selection: $date, displayedComponents: .date)
                    }
                }
                .frame(minHeight: 280)
                .scrollDisabled(true)
            }
        }
    }

    // MARK: - Submit

    private var canSubmit: Bool {
        !merchant.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(normalizedAmountText) != nil
    }

    private var normalizedAmountText: String {
        amountText.replacingOccurrences(of: ",", with: ".")
    }

    private func submit() {
        let info = ReceiptInfo(
            merchant: merchant.trimmingCharacters(in: .whitespaces),
            amount: Double(normalizedAmountText),
            currency: currency,
            date: date,
            rawText: rawText
        )
        onExtracted(info)
    }

    // MARK: - Image loading

    private func loadPickedItem(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                await MainActor.run { onImage(ui) }
            }
        } catch {
            // Silently ignore; user can re-pick.
        }
    }

    private func onImage(_ ui: UIImage) {
        self.image = ui
        Task { await runOCR(on: ui) }
    }

    // MARK: - Camera permission

    private func requestCameraIfNeeded() {
        // UIImagePickerController triggers its own permission alert. Fall back here
        // only when the device has no camera.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            permissionMessage = "当前设备不支持拍照,请选择从相册导入。"
            showPermissionAlert = true
            source = .photos
            return
        }
        showCamera = true
    }

    // MARK: - OCR

    private func runOCR(on ui: UIImage) async {
        guard let cg = ui.cgImage else { return }
        await MainActor.run { isRecognizing = true }

        let result: String = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: strings.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }

        let parsed = ReceiptParser.parse(text: result)
        await MainActor.run {
            self.rawText = result
            self.merchant = parsed.merchant ?? ""
            if let a = parsed.amount {
                self.amountText = String(format: a.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", a)
            }
            if let c = parsed.currency { self.currency = c }
            if let d = parsed.date { self.date = d }
            self.isRecognizing = false
        }
    }
}

// MARK: - Camera wrapper

private struct CameraPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage?) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPicked: (UIImage?) -> Void
        let onCancel: () -> Void

        init(onPicked: @escaping (UIImage?) -> Void, onCancel: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            onPicked(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
