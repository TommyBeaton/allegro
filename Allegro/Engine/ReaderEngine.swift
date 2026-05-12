import Foundation
import Combine

enum ReaderState: Equatable {
    case idle
    case playing
    case paused
    case finished
}

@MainActor
final class ReaderEngine: ObservableObject {
    @Published private(set) var tokens: [Token] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var state: ReaderState = .idle
    @Published var wpm: Int {
        didSet {
            UserDefaults.standard.set(wpm, forKey: DefaultsKey.wpm)
        }
    }

    private var timer: DispatchSourceTimer?

    init(wpm: Int? = nil) {
        self.wpm = wpm ?? UserDefaults.standard.integer(forKey: DefaultsKey.wpm)
        if self.wpm <= 0 { self.wpm = DefaultsValue.wpm }
    }

    var currentToken: Token? {
        guard tokens.indices.contains(currentIndex) else { return nil }
        return tokens[currentIndex]
    }

    var progress: Double {
        guard !tokens.isEmpty else { return 0 }
        return Double(currentIndex) / Double(max(tokens.count - 1, 1))
    }

    // MARK: - Loading

    func load(_ text: String, autoPlay: Bool = true) {
        cancelTimer()
        tokens = Tokeniser.tokenise(text)
        currentIndex = 0
        if tokens.isEmpty {
            state = .idle
        } else if autoPlay {
            play()
        } else {
            state = .paused
        }
    }

    // MARK: - Transport

    func play() {
        guard !tokens.isEmpty else { return }
        if currentIndex >= tokens.count {
            currentIndex = 0
        }
        state = .playing
        scheduleNext()
    }

    func pause() {
        guard state == .playing else { return }
        cancelTimer()
        state = .paused
    }

    func togglePlayPause() {
        switch state {
        case .playing: pause()
        case .paused, .idle: play()
        case .finished:
            currentIndex = 0
            play()
        }
    }

    func step(by delta: Int) {
        let was = state
        cancelTimer()
        let target = currentIndex + delta
        currentIndex = max(0, min(target, max(tokens.count - 1, 0)))
        if was == .playing { scheduleNext() } else { state = .paused }
    }

    func seek(to index: Int) {
        let was = state
        cancelTimer()
        currentIndex = max(0, min(index, max(tokens.count - 1, 0)))
        if was == .playing { scheduleNext() } else if !tokens.isEmpty { state = .paused }
    }

    func setWPM(_ value: Int) {
        wpm = max(50, min(1500, value))
        // future tokens use new WPM automatically; if currently playing,
        // reschedule current token so the change is immediate.
        if state == .playing {
            cancelTimer()
            scheduleNext()
        }
    }

    // MARK: - Timer

    private func scheduleNext() {
        guard state == .playing, let token = currentToken else {
            state = tokens.isEmpty ? .idle : .finished
            return
        }
        let delay = (60.0 / Double(wpm)) * token.baseMultiplier

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + delay)
        t.setEventHandler { [weak self] in
            guard let self else { return }
            self.advance()
        }
        timer = t
        t.resume()
    }

    private func advance() {
        cancelTimer()
        guard state == .playing else { return }
        if currentIndex + 1 >= tokens.count {
            currentIndex = tokens.count - 1
            state = .finished
            return
        }
        currentIndex += 1
        scheduleNext()
    }

    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }
}
