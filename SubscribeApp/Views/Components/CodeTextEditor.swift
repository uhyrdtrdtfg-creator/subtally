import SwiftUI
import UIKit

/// Lets a parent view insert text at the current cursor position of an
/// associated `CodeTextEditor`. Hold one in @State, pass to the editor, then
/// call `insert("{{foo}}")` from anywhere in your view tree (e.g. a sheet).
final class CodeTextEditorController: ObservableObject {
    fileprivate weak var textView: UITextView?

    func insert(_ str: String) {
        guard let tv = textView else { return }
        let cur = tv.text ?? ""
        let nsStr = cur as NSString
        let safeLen = nsStr.length
        let raw = tv.selectedRange
        let loc = max(0, min(raw.location, safeLen))
        let len = max(0, min(raw.length, safeLen - loc))
        let range = NSRange(location: loc, length: len)
        let updated = nsStr.replacingCharacters(in: range, with: str)
        tv.text = updated
        if let coord = tv.delegate as? CodeTextEditor.Coordinator {
            coord.textViewDidChange(tv)
        }
        let newLoc = range.location + (str as NSString).length
        tv.selectedRange = NSRange(location: newLoc, length: 0)
    }
}

/// Plain-text editor for code/JSON/headers — disables smart quotes, dashes,
/// auto-capitalization, autocorrection, and spell check so what the user
/// types is exactly what gets sent. Allows non-ASCII (Chinese etc).
struct CodeTextEditor: UIViewRepresentable {
    @Binding var text: String
    var controller: CodeTextEditorController? = nil
    var font: UIFont = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    func makeUIView(context: Context) -> UITextView {
        let v = UITextView()
        v.font = font
        v.backgroundColor = .clear
        v.autocorrectionType = .no
        v.autocapitalizationType = .none
        v.smartQuotesType = .no
        v.smartDashesType = .no
        v.smartInsertDeleteType = .no
        v.spellCheckingType = .no
        v.delegate = context.coordinator
        v.text = text
        v.textContainerInset = .init(top: 6, left: 0, bottom: 6, right: 0)
        v.textContainer.lineFragmentPadding = 0
        controller?.textView = v
        return v
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        controller?.textView = uiView
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text ?? ""
        }
    }
}

/// Plain-text single-line field with the same no-smart-stuff behavior.
struct CodeTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    func makeUIView(context: Context) -> UITextField {
        let v = UITextField()
        v.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        v.autocorrectionType = .no
        v.autocapitalizationType = .none
        v.smartQuotesType = .no
        v.smartDashesType = .no
        v.smartInsertDeleteType = .no
        v.spellCheckingType = .no
        v.keyboardType = keyboard
        v.placeholder = placeholder
        v.delegate = context.coordinator
        v.text = text
        return v
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }
        @objc func editingChanged(_ tf: UITextField) {
            text = tf.text ?? ""
        }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let cur = textField.text ?? ""
            if let r = Range(range, in: cur) {
                text = cur.replacingCharacters(in: r, with: string)
            }
            return true
        }
    }
}

/// Defensive normalizer — converts curly quotes / em-dash that may have slipped
/// in via paste from rich-text sources back to ASCII equivalents.
extension String {
    func normalizingSmartPunctuation() -> String {
        var s = self
        s = s.replacingOccurrences(of: "\u{201C}", with: "\"")
        s = s.replacingOccurrences(of: "\u{201D}", with: "\"")
        s = s.replacingOccurrences(of: "\u{2018}", with: "'")
        s = s.replacingOccurrences(of: "\u{2019}", with: "'")
        s = s.replacingOccurrences(of: "\u{2014}", with: "--")
        s = s.replacingOccurrences(of: "\u{2013}", with: "-")
        s = s.replacingOccurrences(of: "\u{2026}", with: "...")
        return s
    }
}
