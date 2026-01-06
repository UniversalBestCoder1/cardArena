# 2. 系统静态类图 (Class Diagram - Detailed)

**版本**: 6.1.0 (字段补全版)  
**说明**: 包含类的完整属性定义与方法签名，严格遵循 UML 标准。

---

## 1. 领域实体层 (Domain Entities)

展示数据对象的内部结构。

```mermaid
classDiagram
    %% --- 用户与角色 ---
    class User {
        +String id
        +String username
        +String avatarUrl
        +Date createdAt
    }
    
    class Player {
        +Float balance
        +String lfgStatus
        +Int winCount
    }

    class Staff {
        +String employeeId
        +String shiftSchedule
    }

    class Manager {
        +Int permissionLevel
        +String adminToken
    }

    User <|-- Player
    User <|-- Staff
    User <|-- Manager

    %% --- 资产管理 ---
    class Card {
        +String id
        +String code
        +String name
        +String rarity
        +Float marketPrice
    }

    class InventoryItem {
        +String id
        +Int quantity
        +Boolean isProxy
        +Enum condition
    }

    class Deck {
        +String id
        +String name
        +Enum type
        +Float rentalFee
        +Int likes
    }

    class DeckCard {
        +Int quantity
        +Enum section "Main/Side/Extra"
    }

    User o-- InventoryItem
    User o-- Deck
    Deck *-- DeckCard
    DeckCard --> Card
    InventoryItem --> Card

    %% --- 赛事系统 ---
    class Tournament {
        +String id
        +String title
        +Date startTime
        +Enum status
        +Int maxPlayers
    }

    class TournamentParticipant {
        +Int currentScore
        +Int rank
        +Boolean dropped
    }

    class Match {
        +String id
        +Int roundNumber
        +Int tableNo
        +Int scoreA
        +Int scoreB
    }

    Tournament *-- TournamentParticipant
    Tournament *-- Match
    Match --> Player : PlayerA/B
    TournamentParticipant --> Player

    %% --- 交易与财务 ---
    class TradeListing {
        +String id
        +Float price
        +String description
        +Enum status
    }

    class Order {
        +String id
        +Float amount
        +Date paidAt
    }

    class FinanceLog {
        +Float amount
        +Enum type
        +String relatedId
    }

    User o-- FinanceLog
    User --> TradeListing : Posts
    User --> Order : Creates
    TradeListing <--> Order
    TradeListing --> Card

    %% --- 辅助功能 ---
    class ChatMessage {
        +String content
        +Long timestamp
    }

    class Seat {
        +String label
        +Boolean isOccupied
    }

    User --> ChatMessage : Sends
    User --> Seat : Books
```

---

## 2. 服务层 (Service Layer)

展示业务逻辑类的方法签名。

```mermaid
classDiagram
    class TournamentService {
        +getTournaments() : List~Tournament~
        +createTournament(t: Tournament) : Boolean
        +joinTournament(tId: String, uId: String) : Boolean
        +reportMatch(matchId: String, scoreA: Int, scoreB: Int) : Void
        +pairRound(tId: String) : List~Match~
    }

    class TradeService {
        +postListing(userId: String, cardId: String, price: Float) : Listing
        +buyCard(buyerId: String, listingId: String) : Order
        +cancelListing(listingId: String) : Boolean
    }

    class InventoryService {
        +getMyCards(userId: String) : List~InventoryItem~
        +addCard(userId: String, cardCode: String) : Void
        +validateDeck(deck: Deck) : Boolean
    }

    class FinanceService {
        +recharge(userId: String, amount: Float) : Boolean
        +withdraw(userId: String, amount: Float) : Boolean
        +getLogs(userId: String) : List~FinanceLog~
    }

    class BookingService {
        +getSeats() : List~Seat~
        +bookSeat(userId: String, seatId: String) : Boolean
    }

    %% 依赖关系
    TournamentService ..> Tournament
    TournamentService ..> Match
    TradeService ..> TradeListing
    TradeService ..> Order
    InventoryService ..> InventoryItem
    InventoryService ..> Deck
```