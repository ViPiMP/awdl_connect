//
//  PeerDevice.swift
//  awdl_test
//
//  Created by junjiecui on 2026/3/31.
//


import Foundation
import MultipeerConnectivity

/// Represents a discovered peer device with its connection state.
struct PeerDevice: Identifiable, Hashable {
    let id: MCPeerID
    let displayName: String
    var state: MCSessionState

    var stateDescription: String {
        switch state {
        case .notConnected:
            return "Not Connected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        @unknown default:
            return "Unknown"
        }
    }

    var stateColor: String {
        switch state {
        case .notConnected:
            return "red"
        case .connecting:
            return "orange"
        case .connected:
            return "green"
        @unknown default:
            return "gray"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PeerDevice, rhs: PeerDevice) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}
