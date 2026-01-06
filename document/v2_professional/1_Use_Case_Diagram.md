# 1. 业务全景用例图 (Use Case - Graph Style)

**版本**: 3.2.0 (一致性对齐版)  
**说明**: 每个用例均已映射到具体的 Service 方法和 DB 实体。

---

## 业务功能映射表

| Use Case | Controller / Service | Entity / Table |
| :--- | :--- | :--- |
| **报名参赛** | `TournamentService.joinTournament` | `TOURNAMENT_PARTICIPANTS` |
| **提交比分** | `TournamentService.reportMatchResult` | `MATCHES` |
| **发布挂单** | `TradeService.createListing` | `TRADE_LISTINGS` |
| **购买卡牌** | `TradeService.buyCard` | `ORDERS`, `INVENTORY` |
| **审计流水** | `TradeService.auditTransactions` | `ORDERS`, `FINANCE_LOGS` |

---

## 用例全景图

```mermaid
graph LR
    %% 角色
    Player((牌手/玩家))
    Staff((店员/裁判))
    Manager((店长))

    %% 样式
    classDef actor fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef uc fill:#e1f5fe,stroke:#0277bd,stroke-width:1px,rx:5,ry:5;

    %% --- 1. 赛事模块 ---
    subgraph TourMod [赛事竞技]
        direction TB
        UC_Join[报名参赛]
        UC_Report[提交比分]
        UC_Approve[审批赛事]
    end

    %% --- 2. 交易模块 ---
    subgraph TradeMod [交易市场]
        direction TB
        UC_List[发布挂单]
        UC_Buy[购买卡牌]
        UC_Audit[审计流水]
    end

    %% 连线
    Player --> UC_Join
    Player --> UC_Report
    Player --> UC_List
    Player --> UC_Buy

    Staff --> UC_Report
    Staff --> UC_Approve

    Manager --> UC_Approve
    Manager --> UC_Audit

    class Player,Staff,Manager actor;
    class UC_Join,UC_Report,UC_Approve,UC_List,UC_Buy,UC_Audit uc;
```