import AppKit
import Carbon.HIToolbox

/// Grabs the currently selected text by snapshotting the pasteboard,
/// synthesising a Cmd+C, reading the result, and restoring the original
/// pasteboard contents so the user's clipboard isn't clobbered.
enum SelectionGrabber {
    enum GrabError: Error {
        case accessibilityNotTrusted
        case noTextSelected
        case timeout
    }

    /// Returns the selected text, or throws if nothing was selected within
    /// `timeout` seconds. Accessibility permission is required to post the
    /// synthetic Cmd+C; we check it up-front and prompt the user once.
    ///
    /// 350 ms is generous on purpose — some apps (Notion, Safari with heavy
    /// pages, Microsoft Office) need >100 ms to respond to a synthesised
    /// ⌘C, which the previous 200 ms cap was racing.
    static func grab(timeout: TimeInterval = 0.35) async throws -> String {
        guard ensureAccessibilityTrusted() else {
            throw GrabError.accessibilityNotTrusted
        }

        let pb = NSPasteboard.general
        let snapshot = snapshotPasteboard(pb)
        let countBefore = pb.changeCount

        postCommandC()

        // Poll for the pasteboard to change. We don't block the main thread;
        // the call site is async.
        let deadline = Date().addingTimeInterval(timeout)
        var picked: String?
        while Date() < deadline {
            if pb.changeCount != countBefore {
                picked = pb.string(forType: .string)
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        restorePasteboard(pb, snapshot: snapshot)

        guard let text = picked, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            if picked == nil { throw GrabError.timeout }
            throw GrabError.noTextSelected
        }
        return text
    }

    // MARK: - Accessibility

    /// Returns true if we're trusted; otherwise prompts the user (system dialog) and returns false.
    static func ensureAccessibilityTrusted() -> Bool {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [prompt: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Live trust status without surfacing the system prompt. Used for
    /// post-failure rechecks so we can tell "no text was selected" apart
    /// from "permission was just revoked".
    static func isTrustedSilently() -> Bool {
        AXIsProcessTrusted()
    }

    // MARK: - Cmd+C synthesis

    private static func postCommandC() {
        let src = CGEventSource(stateID: .combinedSessionState)
        // kVK_ANSI_C == 0x08
        let keyCode: CGKeyCode = CGKeyCode(kVK_ANSI_C)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Pasteboard snapshot / restore

    private struct PBItem {
        let types: [NSPasteboard.PasteboardType]
        let data: [NSPasteboard.PasteboardType: Data]
    }

    private static func snapshotPasteboard(_ pb: NSPasteboard) -> [PBItem] {
        guard let items = pb.pasteboardItems else { return [] }
        return items.map { item in
            var data: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let d = item.data(forType: type) {
                    data[type] = d
                }
            }
            return PBItem(types: item.types, data: data)
        }
    }

    private static func restorePasteboard(_ pb: NSPasteboard, snapshot: [PBItem]) {
        pb.clearContents()
        guard !snapshot.isEmpty else { return }
        let newItems: [NSPasteboardItem] = snapshot.map { item in
            let pbItem = NSPasteboardItem()
            for type in item.types {
                if let d = item.data[type] {
                    pbItem.setData(d, forType: type)
                }
            }
            return pbItem
        }
        pb.writeObjects(newItems)
    }
}
