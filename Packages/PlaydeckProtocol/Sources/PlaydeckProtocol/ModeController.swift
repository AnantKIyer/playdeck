import Foundation

/// Errors when requesting an illegal mode transition.
public enum ModeTransitionError: Error, Sendable, Equatable {
    /// Deck and Ride must never run simultaneously — enter one ends the other.
    case mutuallyExclusive(current: AppMode, requested: AppMode)
}

/// Owns exclusive AppMode state. Deck XOR Ride (or neither).
public final class ModeController: @unchecked Sendable {
    public private(set) var mode: AppMode
    private let lock = NSLock()
    private var observers: [@Sendable (AppMode) -> Void] = []

    public init(initial: AppMode = .none) {
        self.mode = initial
    }

    public func onChange(_ handler: @escaping @Sendable (AppMode) -> Void) {
        lock.lock()
        observers.append(handler)
        lock.unlock()
    }

    /// Enter a mode. Entering Deck while in Ride (or vice versa) ends the other first.
    @discardableResult
    public func enter(_ requested: AppMode) -> AppMode {
        lock.lock()
        defer { lock.unlock() }
        if requested == .none {
            mode = .none
            notifyLocked()
            return mode
        }
        // Mutual exclusion: switching modes replaces the previous one.
        if mode != .none && mode != requested {
            mode = .none
            notifyLocked()
        }
        mode = requested
        notifyLocked()
        return mode
    }

    /// Apply a remote `ModeSuggest`, respecting Ride exclusion for USB auto-Deck.
    @discardableResult
    public func applySuggest(
        _ suggest: ModeSuggest,
        respectRideExclusion: Bool = true
    ) -> AppMode {
        lock.lock()
        let current = mode
        lock.unlock()

        if respectRideExclusion && suggest == .deck && current == .ride {
            // Ride wins while user is in a trip — do not auto-enter Deck.
            return current
        }
        return enter(suggest.asAppMode)
    }

    /// Leave the current environment anytime.
    @discardableResult
    public func leave() -> AppMode {
        enter(.none)
    }

    private func notifyLocked() {
        let snapshot = mode
        let handlers = observers
        // Call outside lock would be nicer; observers are sync stubs for MVP scaffold.
        for handler in handlers {
            handler(snapshot)
        }
    }
}
