//
//  WatchConnectivityManager.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import OSLog
import WatchConnectivity

// Watch side of the iPhone connection:
// - receives the RosterSnapshot sent with updateApplicationContext
// - sends MatchEvents right away with sendMessage when the iPhone is reachable,
//   otherwise (or if that fails) queues them with transferUserInfo until it is.
//   The iPhone ignores events it already applied, so a retried event is harmless.
final class WatchConnectivityManager: NSObject {
    var onRosterReceived: ((RosterSnapshot) -> Void)?

    private let session = WCSession.default
    private let logger = Logger(subsystem: "yorgohaykal.Goal-Board.watchkitapp", category: "Connectivity")
    // Events sent before the session finished activating
    private var pendingEvents: [MatchEvent] = []

    func activate() {
        session.delegate = self
        session.activate()
    }

    func send(_ event: MatchEvent) {
        guard session.activationState == .activated else {
            pendingEvents.append(event)
            return
        }
        let payload: [String: Any]
        do {
            payload = try event.payload()
        } catch {
            logger.error("Failed to encode event for the iPhone: \(error)")
            return
        }

        // Keep events in order: if some are already queued, queue this one too
        guard session.isReachable, session.outstandingUserInfoTransfers.isEmpty else {
            session.transferUserInfo(payload)
            return
        }
        session.sendMessage(payload, replyHandler: { _ in }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.logger.error("sendMessage failed, queueing event instead: \(error)")
                    self.session.transferUserInfo(payload)
                }
            }
        })
    }

    private func didActivate() {
        receive(session.receivedApplicationContext)
        let events = pendingEvents
        pendingEvents = []
        events.forEach(send)
    }

    private func receive(_ applicationContext: [String: Any]) {
        do {
            guard let roster = try RosterSnapshot(payload: applicationContext) else { return }
            onRosterReceived?(roster)
        } catch {
            logger.error("Failed to decode roster from the iPhone: \(error)")
        }
    }
}

// WCSession calls these on a background queue, hop back to the main queue in order
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if let error {
                    self.logger.error("WCSession activation failed: \(error)")
                }
                self.didActivate()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.receive(applicationContext) }
        }
    }

    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        guard let error else { return }
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.logger.error("Queued event transfer failed: \(error)") }
        }
    }
}
