//
//  StatusView.swift
//  awdl_test
//
//  Created by junjiecui on 2026/3/31.
//


import SwiftUI

/// Status view showing current connection details and device information.
struct StatusView: View {
    @EnvironmentObject var manager: MultipeerManager

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Device Info
                Section("This Device") {
                    InfoRow(label: "Name", value: manager.localDisplayName, icon: "iphone")
                    InfoRow(label: "Advertising", value: manager.isAdvertising ? "Active" : "Inactive",
                            icon: "antenna.radiowaves.left.and.right",
                            valueColor: manager.isAdvertising ? .green : .secondary)
                    InfoRow(label: "Browsing", value: manager.isBrowsing ? "Active" : "Inactive",
                            icon: "magnifyingglass",
                            valueColor: manager.isBrowsing ? .blue : .secondary)
                }

                // MARK: - Connection Stats
                Section("Connection Statistics") {
                    InfoRow(label: "Discovered Peers", value: "\(manager.discoveredPeers.count)", icon: "eye.fill")
                    InfoRow(label: "Connected Peers", value: "\(manager.connectedPeers.count)", icon: "link")
                    InfoRow(label: "Messages Sent/Received", value: "\(manager.messages.count)", icon: "message.fill")
                }

                // MARK: - Connected Peers Detail
                Section("Connected Peers Detail") {
                    if manager.connectedPeers.isEmpty {
                        Text("No peers connected")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(manager.connectedPeers) { peer in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                VStack(alignment: .leading) {
                                    Text(peer.displayName)
                                        .font(.body)
                                    Text(peer.stateDescription)
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }

                // MARK: - About AWDL
                Section("About AWDL") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apple Wireless Direct Link")
                            .font(.headline)
                        Text("AWDL is Apple's proprietary protocol for peer-to-peer communication. MultipeerConnectivity uses AWDL to enable direct device-to-device connections without requiring a shared Wi-Fi network.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Key Features:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.top, 4)
                        BulletPoint("No shared Wi-Fi required")
                        BulletPoint("Direct peer-to-peer connection")
                        BulletPoint("Does not interfere with existing Wi-Fi")
                        BulletPoint("Uses 5GHz Wi-Fi channel for AWDL")
                        BulletPoint("Automatic peer discovery")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Status")
        }
    }
}

/// A row displaying a label-value pair with an icon.
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}

/// A bullet point text view.
struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatusView()
        .environmentObject(MultipeerManager())
}
