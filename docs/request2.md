# 需求文档

这是一个Apple的awdl 连接的demo应用，使用两台设备测试的时候，为什么会一直显示下面的日志
```log
Found peer: CJJ_IPad_Debug
Added peer: CJJ_IPad_Debug
Peers found nums: 1
Invited peer: CJJ_IPad_Debug
Peer CJJ_IPad_Debug changed state to: Connecting
Peer CJJ_IPad_Debug changed state to: Connected
Lost peer: CJJ_IPad_Debug
```
基本都是发现后过几秒又断开，导致连接过程被中断，为什么Apple官方的基于awdl协议的airdrop等功能却能稳定建立连接？