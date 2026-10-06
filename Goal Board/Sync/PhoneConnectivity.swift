//
//  PhoneConnectivity.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import OSLog
import SwiftData
import WatchConnectivity

// iPhone side of the Watch connection:
// - sends the latest RosterSnapshot whenever the store is saved
// - applies MatchEvents from the Watch, sent as messages or queued user info
@MainActor
final class PhoneConnectivity: NSObject {
    private let container: ModelContainer
    private let session: WCSession? = WCSession.isSupported() ? .default : nil
    private var lastSentRoster: RosterSnapshot?
    private var saveObserver: NSObjectProtocol?
    private let logger = Logger(subsystem: "yorgohaykal.Goal-Board", category: "Connectivity")

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
            logger.error("Failed to send roster to the Watch: \(error)")
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
            logger.error("Failed to apply event from the Watch: \(error)")
        }
    }
}

// WCSession calls these on a background queue. DispatchQueue.main keeps events in the
// order they were received, which matters (a goal must be applied before its removal).
extension PhoneConnectivity: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if let error {
                    self.logger.error("WCSession activation failed: \(error)")
                }
                self.sendRoster()
            }
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

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.receive(message) }
            replyHandler([:])
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    // Called when the user switches to another Watch; activate again for the new one
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
