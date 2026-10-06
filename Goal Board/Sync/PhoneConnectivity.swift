//
//  PhoneConnectivity.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import SwiftData
import WatchConnectivity

// iPhone side of the Watch connection:
// - sends the latest RosterSnapshot whenever the store is saved
// - applies MatchEvents queued by the Watch
@MainActor
final class PhoneConnectivity: NSObject {
    private let container: ModelContainer
    private let session: WCSession? = WCSession.isSupported() ? .default : nil
    private var lastSentRoster: RosterSnapshot?
    private var saveObserver: NSObjectProtocol?

    init(container: ModelContainer) {
        self.container = container
        super.init()
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()

        saveObserver = NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.sendRoster() }
        }
    }

    func sendRoster() {
        guard let session,
              session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else { return }
        do {
            let roster = try RosterSnapshot(context: container.mainContext)
            if let lastSentRoster, roster.hasSameContent(as: lastSentRoster) { return }
            try session.updateApplicationContext(roster.payload())
            lastSentRoster = roster
        } catch {
            print("Failed to send roster to the Watch: \(error)")
        }
    }

    private func receive(_ payload: [String: Any]) {
        do {
            guard let event = try MatchEvent(payload: payload) else { return }
            let context = container.mainContext
            if try MatchEventApplier(context: context).apply(event) {
                try context.save()
            }
        } catch {
            print("Failed to apply event from the Watch: \(error)")
        }
    }
}

// WCSession calls these on a background queue. DispatchQueue.main keeps events in the
// order they were received, which matters (a goal must be applied before its removal).
extension PhoneConnectivity: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation failed: \(error)")
        }
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.sendRoster() }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                self.lastSentRoster = nil
                self.sendRoster()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.receive(userInfo) }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    // Called when the user switches to another Watch; activate again for the new one
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
