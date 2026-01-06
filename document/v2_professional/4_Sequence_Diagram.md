# 4. 核心业务序列图 (Business Sequence Diagram)

**版本**: 6.0.0 (纯业务版)  
**说明**: 描述业务角色与系统各功能模块之间的交互，隐藏底层技术实现细节。

---

## 场景 A: 赛事报名与资格审核 (Tournament Enrollment)

描述玩家报名参加比赛的业务流转。

```mermaid
sequenceDiagram
    autonumber
    actor Player as 玩家
    participant App as 移动端
    participant TourSystem as 赛事系统
    participant AssetSystem as 资产系统

    Player->>App: 浏览比赛并点击 "报名"
    App->>TourSystem: 提交报名申请 (User, TourID)
    
    TourSystem->>TourSystem: 校验参赛资格 (名额/限制)
    
    alt 资格校验不通过
        TourSystem-->>App: 报名失败 (名额已满/资格不符)
        App-->>Player: 提示错误
    else 校验通过
        TourSystem->>AssetSystem: 请求扣除报名费
        
        alt 余额不足
            AssetSystem-->>TourSystem: 扣款失败
            TourSystem-->>App: 提示余额不足，请充值
        else 扣款成功
            AssetSystem-->>TourSystem: 确认资金冻结
            TourSystem->>TourSystem: 生成参赛凭证
            TourSystem-->>App: 报名成功
            App-->>Player: 展示电子入场券
        end
    end
```

---

## 场景 B: 线下交易与实物交割 (O2O Trade Fulfillment)

描述买卖双方在实体店进行卡牌交割的业务流程。

```mermaid
sequenceDiagram
    autonumber
    actor Seller as 卖家
    actor Staff as 店员
    participant POS as 柜台终端
    participant TradeSystem as 交易中心
    participant StockSystem as 库存中心
    actor Buyer as 买家

    Note over Seller, Buyer: 前提：线上订单已支付，资金托管中

    Seller->>Staff: 到店出示 "发货码"
    Staff->>POS: 扫描发货码
    POS->>TradeSystem: 验证发货请求
    TradeSystem-->>POS: 显示商品清单与品相要求

    Staff->>Staff: 实物验货 (核对卡牌/品相)
    
    alt 验货通过
        Staff->>POS: 确认收货入仓
        POS->>StockSystem: 执行库存转移 (卖家 -> 店铺暂存)
        StockSystem-->>POS: 库存锁定成功
        
        Buyer->>Staff: 出示 "提货码"
        Staff->>POS: 扫描提货码
        POS->>TradeSystem: 确认最终交付
        
        par 结算流程
            TradeSystem->>TradeSystem: 解冻资金 -> 打给卖家
            StockSystem->>StockSystem: 转移库存 (店铺 -> 买家)
        end
        
        TradeSystem-->>POS: 订单完结
        Staff->>Buyer: 交付实物卡牌
    else 验货不符
        Staff->>POS: 标记异常/拒收
        POS->>TradeSystem: 挂起订单，发起仲裁
    end
```

---

## 场景 C: 卡组构筑与合规性检查 (Deck Building & Compliance)

描述玩家组建套牌并接受禁卡表检查的流程。

```mermaid
sequenceDiagram
    autonumber
    actor Player as 玩家
    participant DeckBuilder as 组卡器
    participant StockSystem as 个人卡库
    participant RuleEngine as 规则引擎 (禁卡表)

    Player->>DeckBuilder: 打开组卡界面
    DeckBuilder->>StockSystem: 拉取持有卡牌列表
    StockSystem-->>DeckBuilder: 返回可用卡池

    loop 构筑过程
        Player->>DeckBuilder: 添加卡牌
        DeckBuilder->>DeckBuilder: 检查持有数量 (是否够用?)
    end

    Player->>DeckBuilder: 点击 "保存卡组"
    DeckBuilder->>RuleEngine: 提交卡组清单进行审核
    
    RuleEngine->>RuleEngine: 校验：<br/>1. 卡组张数限制<br/>2. 禁限卡表 (Banlist)<br/>3. 同名卡上限
    
    alt 违规
        RuleEngine-->>DeckBuilder: 审核失败 (包含违禁卡)
        DeckBuilder-->>Player: 标红违规卡牌，提示修改
    else 合规
        RuleEngine-->>DeckBuilder: 审核通过
        DeckBuilder->>DeckBuilder: 保存卡组配置
        DeckBuilder-->>Player: 保存成功
    end
```

---

## 场景 D: 社区互动与预约 (Social & Booking)

描述玩家预约座位并呼叫对手的流程。

```mermaid
sequenceDiagram
    autonumber
    actor PlayerA as 玩家A
    actor PlayerB as 玩家B
    participant BookingSystem as 预约系统
    participant ChatSystem as 聊天系统

    PlayerA->>BookingSystem: 预约 5号桌
    BookingSystem->>BookingSystem: 锁定座位资源
    BookingSystem-->>PlayerA: 预约成功

    PlayerA->>ChatSystem: 发送广播 "5号桌来人!"
    ChatSystem->>ChatSystem: 消息分发 (Push)
    ChatSystem-->>PlayerB: 收到对战邀请

    PlayerB->>BookingSystem: 申请加入 5号桌
    BookingSystem->>BookingSystem: 关联对战双方
    BookingSystem-->>PlayerB: 加入成功
    BookingSystem-->>PlayerA: 通知对手已就位
```