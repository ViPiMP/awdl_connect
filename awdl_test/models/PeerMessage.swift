//
//  PeerMessage.swift
//  awdl_test
//
//  Created by junjiecui on 2026/3/31.
//


import Foundation

/// Represents a message exchanged between connected peers.
struct PeerMessage: Identifiable, Codable {
    let id: UUID
    let senderName: String
    let content: String
    let timestamp: Date

    init(senderName: String, content: String) {
        self.id = UUID()
        self.senderName = senderName
        self.content = content
        self.timestamp = Date()
    }
}
