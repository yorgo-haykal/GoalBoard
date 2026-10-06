//
//  WatchPayload.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 05/10/2026.
//

import Foundation

// WatchConnectivity only carries property-list dictionaries, so each message is
// JSON-encoded and stored under a single key.
enum WatchPayload {
    static let rosterKey = "roster"
    static let eventKey = "matchEvent"

    static func encode<T: Encodable>(_ value: T, key: String) throws -> [String: Any] {
        [key: try JSONEncoder().encode(value)]
    }

    // Returns nil when the dictionary doesn't contain `key`, throws when it does but can't be decoded
    static func decode<T: Decodable>(_ type: T.Type, key: String, from dictionary: [String: Any]) throws -> T? {
        guard let data = dictionary[key] as? Data else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}

extension RosterSnapshot {
    func payload() throws -> [String: Any] {
        try WatchPayload.encode(self, key: WatchPayload.rosterKey)
    }

    init?(payload: [String: Any]) throws {
        guard let snapshot = try WatchPayload.decode(RosterSnapshot.self, key: WatchPayload.rosterKey, from: payload) else { return nil }
        self = snapshot
    }
}

extension MatchEvent {
    func payload() throws -> [String: Any] {
        try WatchPayload.encode(self, key: WatchPayload.eventKey)
    }

    init?(payload: [String: Any]) throws {
        guard let event = try WatchPayload.decode(MatchEvent.self, key: WatchPayload.eventKey, from: payload) else { return nil }
        self = event
    }
}
