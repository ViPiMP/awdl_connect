//
//  ChatView.swift
//  awdl_test
//
//  Created by junjiecui on 2026/3/31.
//


import SwiftUI
import MultipeerConnectivity

/// Need to import this for MCSessionState usage in PeerRow
/// (already imported via ConnectionView but needed for standalone preview)

/// Chat view for sending and receiving messages between connected peers.
struct ChatView: View {
    @EnvironmentObject var manager: MultipeerManager
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Connection Status Bar
                if manager.connectedPeers.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("No peers connected. Go to Connect tab to find devices.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.orange.opacity(0.1))
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to \(manager.connectedPeers.count) peer(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.1))
                }

                // MARK: - Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromMe: message.senderName == manager.localDisplayName
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: manager.messages.count) { _, _ in
                        if let lastMessage = manager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if manager.messages.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No messages yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Connect to a peer and start chatting")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }

                Divider()

                // MARK: - Message Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.connectedPeers.isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Chat")
        }
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        manager.sendMessage(trimmed)
        messageText = ""
    }
}

/// A chat bubble view for displaying a single message.
struct MessageBubble: View {
    let message: PeerMessage
    let isFromMe: Bool

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                if !isFromMe {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isFromMe ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(MultipeerManager())
}
