import Foundation

enum ReadingMode: String, CaseIterable, Identifiable {
    case rsvp
    // v2: case bionic, chunked

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rsvp: return "RSVP"
        }
    }
}
