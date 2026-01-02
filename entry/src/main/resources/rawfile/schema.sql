-- 数据库版本: CardArena_v11.db
-- 生成时间: 2025-12-31

-- 1. 赛事表
CREATE TABLE IF NOT EXISTS tournaments (
  id TEXT PRIMARY KEY, 
  title TEXT, 
  gameType TEXT, 
  format TEXT, 
  startTime TEXT, 
  status TEXT, 
  maxPlayers INTEGER, 
  currentPlayers INTEGER, 
  entryFee INTEGER, 
  location TEXT, 
  description TEXT,
  organizerType TEXT,
  organizerName TEXT,
  requireReferee INTEGER,
  allowedDecks TEXT
);

-- 2. 卡组表
CREATE TABLE IF NOT EXISTS decks (
  id TEXT PRIMARY KEY, 
  name TEXT, 
  gameType TEXT, 
  rentalFeePerHour INTEGER, 
  deposit INTEGER, 
  stock INTEGER, 
  description TEXT, 
  tags TEXT, 
  composition TEXT
);

-- 3. 报名表
CREATE TABLE IF NOT EXISTS enrollments (
  id INTEGER PRIMARY KEY AUTOINCREMENT, 
  tournament_id TEXT, 
  user_id TEXT
);

-- 4. 租借记录表
CREATE TABLE IF NOT EXISTS rentals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deck_id TEXT,
  rent_time INTEGER,
  status INTEGER DEFAULT 0,
  user_id TEXT
);

-- 5. 单卡库存表
CREATE TABLE IF NOT EXISTS singles (
  id TEXT PRIMARY KEY,
  name TEXT,
  card_code TEXT,
  rarity TEXT,
  stock INTEGER,
  price INTEGER,
  is_proxy INTEGER DEFAULT 0
);

-- 6. 座位预约表
CREATE TABLE IF NOT EXISTS seat_bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seat_id TEXT,
  book_date TEXT,
  user_id TEXT
);

-- 7. 用户表
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT,
  password TEXT,
  role TEXT,
  wallet_balance INTEGER DEFAULT 0
);

-- 8. 聊天消息表
CREATE TABLE IF NOT EXISTS chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sender_id TEXT,
  sender_name TEXT,
  sender_role TEXT,
  receiver_id TEXT,
  content TEXT,
  timestamp INTEGER
);

-- 9. 交易流水表
CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  type TEXT,
  amount INTEGER,
  reference_id TEXT,
  timestamp INTEGER
);
