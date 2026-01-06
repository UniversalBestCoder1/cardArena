# CardArena 业务架构设计说明书

**版本**: 3.1.0 (布局优化版)  
**日期**: 2026-01-06  
**说明**: 优化图表布局，减少连线交叉，提升可读性。

---

## 1. 业务能力全景图 (Business Capability Map)

采用“分层”视图，从左至右展示用户触达、核心服务与底层支撑的关系。

```mermaid
graph LR
    %% --- 样式定义 ---
    classDef channel fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px;
    classDef core fill:#e1f5fe,stroke:#0277bd,stroke-width:1px;
    classDef support fill:#fff3e0,stroke:#ef6c00,stroke-width:1px;

    %% --- 1. 渠道入口 (左侧) ---
    subgraph Channels [触达渠道]
        direction TB
        App[玩家 App]
        Admin[管理后台]
    end

    %% --- 2. 核心业务 (中间) ---
    %% 使用子图将功能聚类，内部尽量简单连接以保持紧凑
    subgraph Core [核心业务域]
        direction TB
        
        subgraph TourBiz [赛事运营]
            direction LR
            T1[排期发布] --- T2[报名签到] --- T3[编排对阵] --- T4[积分排名]
        end

        subgraph TradeBiz [交易流通]
            direction LR
            Tr1[行情查询] --- Tr2[挂单买卖] --- Tr3[订单撮合] --- Tr4[交割结算]
        end

        subgraph DeckBiz [卡牌构筑]
            direction LR
            D1[卡牌百科] --- D2[组卡器] --- D3[卡组分享] --- D4[试抽模拟]
        end
        
        subgraph VenueBiz [场馆资源]
            direction LR
            V1[座位预约] --- V2[裁判预约] --- V3[核销]
        end
    end

    %% --- 3. 支撑中心 (右侧) ---
    subgraph Support [支撑中心]
        direction TB
        UC[用户中心<br/>注册/认证/档案]
        AC[资产中心<br/>钱包/支付/对账]
        SC[库存中心<br/>商品/卡本/盘点]
    end

    %% --- 关键连线 (减少交叉) ---
    %% 渠道 -> 核心
    App --> TourBiz
    App --> TradeBiz
    App --> DeckBiz
    App --> VenueBiz
    
    Admin --> TourBiz
    Admin --> TradeBiz
    Admin --> VenueBiz

    %% 核心 -> 支撑
    TourBiz --> UC
    TourBiz --> AC
    TradeBiz --> AC
    TradeBiz --> SC
    DeckBiz --> SC
    VenueBiz --> UC

    %% --- 样式应用 ---
    class App,Admin channel;
    class T1,T2,T3,T4,Tr1,Tr2,Tr3,Tr4,D1,D2,D3,D4,V1,V2,V3 core;
    class UC,AC,SC support;
```

---

## 2. 核心业务流程 (Key Business Processes)

### 2.1 玩家参赛流程

```mermaid
graph LR
    %% 紧凑型流程图
    Start((开始)) --> Browse[浏览赛事]
    Browse --> Join{报名支付}
    
    Join -- 成功 --> Ticket[获得凭证]
    Ticket --> CheckIn[现场签到]
    
    subgraph MatchLoop [循环赛程]
        CheckIn --> Pair[系统配对]
        Pair --> Battle[线下对战]
        Battle --> Report[确认比分]
    end
    
    Report --> Rank[生成排名]
    Rank --> Reward[发放奖励]
    Reward --> End((结束))
```

### 2.2 交易结算流程

```mermaid
sequenceDiagram
    autonumber
    participant Buyer as 买家
    participant Sys as 交易系统
    participant Wallet as 钱包
    participant Stock as 库存
    participant Seller as 卖家

    Note over Buyer, Seller: 一口价购买流程

    Buyer->>Sys: 购买商品
    Sys->>Wallet: 冻结买家资金
    
    alt 资金冻结成功
        Sys->>Stock: 锁定库存
        Sys->>Seller: 推送发货通知
        Seller->>Sys: 确认发货/交接
        Buyer->>Sys: 确认收货
        
        par 结算操作
            Sys->>Wallet: 资金划转 (买家->卖家)
            Sys->>Stock: 库存划转 (卖家->买家)
        end
        
        Sys-->>Buyer: 交易完成
    else 余额不足
        Sys-->>Buyer: 提示充值
    end
```

---

## 3. 权限矩阵简表

| 角色 | 赛事能力 | 交易能力 | 资产能力 |
| :--- | :--- | :--- | :--- |
| **玩家** | 报名, 参赛 | 买卖, 挂单 | 充值, 提现 |
| **管理员** | **排表, 判罚** | **下架, 监管** | **退款, 对账** |
| **裁判** | 确认比分 | - | - |
