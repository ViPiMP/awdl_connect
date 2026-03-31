//
//  ConnectionView.swift
//  awdl_test
//
//  Created by junjiecui on 2026/3/31.
//


import SwiftUI
import MultipeerConnectivity

/// View for managing AWDL connections: advertising, browsing, and connecting to peers.
struct ConnectionView: View {
    @EnvironmentObject var manager: MultipeerManager

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Service Controls
                Section {
                    Toggle(isOn: Binding(
                        get: { manager.isAdvertising },
                        set: { newValue in
                            if newValue {
                                manager.startAdvertising()
                            } else {
                                manager.stopAdvertising()
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(manager.isAdvertising ? .green : .secondary)
                                .symbolEffect(.pulse, isActive: manager.isAdvertising)
                            VStack(alignment: .leading) {
                                Text("Advertise")
                                    .font(.body)
                                Text("Make this device discoverable")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Toggle(isOn: Binding(
                        get: { manager.isBrowsing },
                        set: { newValue in
                            if newValue {
                                manager.startBrowsing()
                            } else {
                                manager.stopBrowsing()
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(manager.isBrowsing ? .blue : .secondary)
                                .symbolEffect(.pulse, isActive: manager.isBrowsing)
                            VStack(alignment: .leading) {
                                Text("Browse")
                                    .font(.body)
                                Text("Search for nearby devices")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("AWDL Services")
                } footer: {
                    Text("Enable both Advertise and Browse to discover and connect with nearby devices via AWDL. No shared Wi-Fi required.")
                }

                // MARK: - Discovered Peers
                Section {
                    if manager.discoveredPeers.isEmpty {
                        HStack {
                            Spacer()
                            if manager.isBrowsing {
                                VStack(spacing: 8) {
                                    ProgressView()
                                    Text("Searching for nearby devices...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "wifi.slash")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text("Enable Browse to discover devices")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 20)
                            }
                            Spacer()
                        }
                    } else {
                        ForEach(manager.discoveredPeers) { peer in
                            PeerRow(peer: peer) {
                                manager.invitePeer(peer)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Discovered Peers")
                        Spacer()
                        Text("\(manager.discoveredPeers.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                // MARK: - Connected Peers
                Section {
                    if manager.connectedPeers.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "person.2.slash")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("No connected devices")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(manager.connectedPeers) { peer in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(peer.displayName)
                                    .font(.body)
                                Spacer()
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Connected Peers")
                        Spacer()
                        Text("\(manager.connectedPeers.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                // MARK: - Actions
                if !manager.connectedPeers.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            manager.disconnect()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect All")
                            }
                        }
                    }
                }
            }
            .navigationTitle("AWDL Connect")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            manager.startAdvertising()
                            manager.startBrowsing()
                        } label: {
                            Label("Start All", systemImage: "play.fill")
                        }

                        Button(role: .destructive) {
                            manager.stopAll()
                        } label: {
                            Label("Stop All", systemImage: "stop.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

/// Row view for a discovered peer.
struct PeerRow: View {
    let peer: PeerDevice
    let onConnect: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(colorForState(peer.state))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading) {
                Text(peer.displayName)
                    .font(.body)
                Text(peer.stateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if peer.state == .notConnected {
                Button("Connect") {
                    onConnect()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else if peer.state == .connecting {
                ProgressView()
                    .controlSize(.small)
            } else if peer.state == .connected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForState(_ state: MCSessionState) -> Color {
        switch state {
        case .notConnected: return .red
        case .connecting: return .orange
        case .connected: return .green
        @unknown default: return .gray
        }
    }
}

#Preview {
    ConnectionView()
        .environmentObject(MultipeerManager())
}
