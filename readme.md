# 基于AWDL协议的近场连接

## 框架使用简介

Apple通信核心部分使用的是MultipeerConnectivity框架，UI部分使用的是SwiftUI框架、Combine支持响应式编程

## 设备支持

- [x] IPhone
- [x] IPad
- [x] MacOS

## 目前问题解决情况

- [x] awdl连接极其不稳定，加固 
- [x] 发现上一次连接的设备，进行自动连接


## 效果展示

### 一、服务界面
<img src="assets/connectView.PNG" alt="连接" width="30%">

### 二、聊天界面
<img src="assets/chatView.PNG" alt="聊天" width="30%">   

<br>

## 项目架构概览

### 项目架构

```mermaid
graph TB
    subgraph "App Entry"
        A["awdl_testApp<br/>(@main)"]
    end

    subgraph "View Layer (SwiftUI)"
        B["ContentView<br/>TabView 容器<br/>@StateObject MultipeerManager"]
        C["ConnectionView<br/>设备发现与连接"]
        D["ChatView<br/>即时通讯"]
        E["StatusView<br/>状态监控"]
        C1["PeerRow<br/>设备行组件"]
        D1["MessageBubble<br/>消息气泡组件"]
        E1["InfoRow / BulletPoint<br/>信息展示组件"]
    end

    subgraph "Service Layer"
        F["MultipeerManager<br/>ObservableObject<br/>核心服务管理器"]
    end

    subgraph "Model Layer"
        G["PeerDevice<br/>设备模型"]
        H["PeerMessage<br/>消息模型"]
    end

    subgraph "Apple Framework"
        I["MCSession"]
        J["MCNearbyServiceAdvertiser"]
        K["MCNearbyServiceBrowser"]
    end

    A --> B
    B -->|".environmentObject()"| C
    B -->|".environmentObject()"| D
    B -->|".environmentObject()"| E
    C --> C1
    D --> D1
    E --> E1

    C -->|"startAdvertising / startBrowsing / invitePeer"| F
    D -->|"sendMessage"| F
    F -->|"@Published 数据驱动"| C
    F -->|"@Published 数据驱动"| D
    F -->|"@Published 数据驱动"| E

    F --> G
    F --> H
    F -->|"delegate"| I
    F -->|"delegate"| J
    F -->|"delegate"| K
```

### 完整业务UML流程图

```mermaid
flowchart TD
    START(["App 启动"]) --> INIT["awdl_testApp 创建 WindowGroup"]
    INIT --> CV["ContentView 初始化<br/>@StateObject 创建 MultipeerManager"]
    CV --> SESSION["MultipeerManager.init()<br/>创建 MCPeerID<br/>创建 MCSession (加密: .optional)"]
    CV --> TAB{"TabView 三个标签页"}

    TAB --> TAB1["🔗 Connect Tab<br/>ConnectionView"]
    TAB --> TAB2["💬 Chat Tab<br/>ChatView"]
    TAB --> TAB3["ℹ️ Status Tab<br/>StatusView"]

    %% ===== 设备发现与连接流程 =====
    TAB1 --> ADV_ON{{"用户开启 Advertise"}}
    TAB1 --> BRW_ON{{"用户开启 Browse"}}

    ADV_ON --> ADV["创建 MCNearbyServiceAdvertiser<br/>服务类型: awdl-connect<br/>开始广播"]
    BRW_ON --> BRW["创建 MCNearbyServiceBrowser<br/>服务类型: awdl-connect<br/>开始扫描"]

    BRW --> FOUND["📡 foundPeer 回调<br/>发现附近设备"]
    FOUND --> CHECK_CONNECTED{"该 peer 是否<br/>已通过 Session 连接?"}
    CHECK_CONNECTED -->|"是"| SKIP["跳过，不添加"]
    CHECK_CONNECTED -->|"否"| ADD["添加到 discoveredPeers 列表"]
    ADD --> CHECK_LAST{"是否为上次<br/>连接过的 peer?"}
    CHECK_LAST -->|"是"| AUTO_INVITE["自动发起邀请<br/>(自动重连)"]
    CHECK_LAST -->|"否"| SHOW["UI 显示设备<br/>PeerRow 组件"]

    SHOW --> USER_CONNECT{{"用户点击 Connect"}}
    USER_CONNECT --> INVITE["invitePeer()<br/>browser.invitePeer()<br/>超时: 30秒"]
    AUTO_INVITE --> INVITE

    INVITE --> PEER_B["对方设备收到邀请<br/>advertiser didReceiveInvitation"]
    PEER_B --> ACCEPT["自动接受邀请<br/>invitationHandler(true, session)"]

    ACCEPT --> CONNECTING["MCSession 状态: .connecting"]
    CONNECTING --> CONNECTED["MCSession 状态: .connected ✅"]

    CONNECTED --> STOP_DISC["停止 Browser 和 Advertiser<br/>(防止发现层干扰已建立的连接)"]
    CONNECTED --> UPDATE_UI["更新 connectedPeers 列表<br/>UI 显示已连接"]

    %% ===== Lost Peer 处理 =====
    BRW --> LOST["📡 lostPeer 回调<br/>发现层丢失设备"]
    LOST --> CHECK_SESSION{"Session 层<br/>是否仍连接?"}
    CHECK_SESSION -->|"是"| KEEP["保留设备，不移除<br/>(AWDL 信号间歇性)"]
    CHECK_SESSION -->|"否"| REMOVE["从 discoveredPeers 移除"]

    %% ===== 断开与自动重连 =====
    CONNECTED --> DISC_EVENT["MCSession 状态: .notConnected<br/>(意外断开)"]
    DISC_EVENT --> AUTO_CHECK{"shouldAutoReconnect?"}
    AUTO_CHECK -->|"是"| DELAY["延迟 2 秒"]
    DELAY --> RESTART["重启 Advertiser + Browser<br/>等待重新发现 peer"]
    RESTART --> FOUND
    AUTO_CHECK -->|"否 (用户主动断开)"| CLEAN["清理状态"]

    %% ===== 聊天流程 =====
    TAB2 --> MSG_INPUT{{"用户输入消息<br/>点击发送 / 回车"}}
    MSG_INPUT --> ENCODE["创建 PeerMessage<br/>JSONEncoder 编码为 Data"]
    ENCODE --> SEND["MCSession.send()<br/>模式: .reliable<br/>发送给所有已连接 peer"]
    SEND --> LOCAL_APPEND["本地 messages 数组追加"]
    LOCAL_APPEND --> UI_SCROLL["UI 自动滚动到最新消息"]

    SEND -.->|"网络传输"| RECEIVE["对方设备<br/>MCSessionDelegate<br/>didReceive data"]
    RECEIVE --> DECODE["JSONDecoder 解码<br/>还原 PeerMessage"]
    DECODE --> REMOTE_APPEND["对方 messages 数组追加"]
    REMOTE_APPEND --> REMOTE_UI["对方 UI 显示消息气泡"]

    %% ===== 状态监控 =====
    TAB3 --> STATUS["StatusView 实时展示:<br/>• 本机名称/广播/搜索状态<br/>• 已发现/已连接设备数<br/>• 消息总数<br/>• 已连接设备详情"]

    %% ===== 样式 =====
    style START fill:#4CAF50,color:#fff
    style CONNECTED fill:#4CAF50,color:#fff
    style STOP_DISC fill:#FF9800,color:#fff
    style KEEP fill:#2196F3,color:#fff
    style DISC_EVENT fill:#f44336,color:#fff
    style CLEAN fill:#9E9E9E,color:#fff
```
