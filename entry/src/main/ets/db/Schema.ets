export class DDL {
  static readonly TOURNAMENTS = `
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
      organizerId TEXT,
      poster TEXT,
      requireReferee INTEGER,
      allowedDecks TEXT,
      refereeId TEXT
    )
  `;
  static readonly DECKS = `CREATE TABLE IF NOT EXISTS decks (id TEXT PRIMARY KEY, name TEXT, gameType TEXT, rentalFeePerHour INTEGER, deposit INTEGER, stock INTEGER, description TEXT, tags TEXT, composition TEXT, cover_image TEXT)`;
  static readonly ENROLLMENTS = `CREATE TABLE IF NOT EXISTS enrollments (id INTEGER PRIMARY KEY AUTOINCREMENT, tournament_id TEXT, user_id TEXT)`;
  static readonly RENTALS = `
    CREATE TABLE IF NOT EXISTS rentals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      deck_id TEXT,
      rent_time INTEGER,
      status INTEGER DEFAULT 0,
      user_id TEXT
    )
  `;
  static readonly SINGLES = `
    CREATE TABLE IF NOT EXISTS singles (
      id TEXT PRIMARY KEY,
      name TEXT,
      card_code TEXT,
      rarity TEXT,
      stock INTEGER,
      price INTEGER,
      is_proxy INTEGER DEFAULT 0
    )
  `;
  static readonly SEAT_BOOKINGS = `
    CREATE TABLE IF NOT EXISTS seat_bookings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seat_id TEXT,
      book_date TEXT,
      user_id TEXT
    )
  `;
  static readonly USERS = `
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT,
      password TEXT,
      role TEXT,
      wallet_balance INTEGER DEFAULT 0,
      referee_profile TEXT,
      lfg_status TEXT, 
      lfg_message TEXT
    )
  `;

  static readonly DECK_POSTS = `
    CREATE TABLE IF NOT EXISTS deck_posts (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      deck_json TEXT,
      title TEXT,
      description TEXT,
      likes INTEGER DEFAULT 0,
      created_at INTEGER
    )
  `;

  static readonly DECK_LIKES = `
    CREATE TABLE IF NOT EXISTS deck_likes (
      post_id TEXT,
      user_id TEXT,
      PRIMARY KEY (post_id, user_id)
    )
  `;

  static readonly DECK_COMMENTS = `
    CREATE TABLE IF NOT EXISTS deck_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      post_id TEXT,
      user_id TEXT,
      content TEXT,
      created_at INTEGER
    )
  `;

  static readonly TRADE_LISTINGS = `
    CREATE TABLE IF NOT EXISTS trade_listings (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      type TEXT, 
      game_type TEXT,
      card_name TEXT,
      price INTEGER,
      description TEXT,
      status INTEGER DEFAULT 0,
      created_at INTEGER
    )
  `;

  static readonly CARD_DATABASE = `
    CREATE TABLE IF NOT EXISTS card_database (
      id TEXT PRIMARY KEY,
      name TEXT,
      game_type TEXT,
      card_code TEXT,
      rarity TEXT,
      type TEXT 
    )
  `;

  static readonly FRIENDS = `
    CREATE TABLE IF NOT EXISTS friends (
      user_id TEXT,
      friend_id TEXT,
      created_at INTEGER,
      PRIMARY KEY (user_id, friend_id)
    )
  `;
  static readonly CHAT_MESSAGES = `
    CREATE TABLE IF NOT EXISTS chat_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender_id TEXT,
      sender_name TEXT,
      sender_role TEXT,
      receiver_id TEXT,
      content TEXT,
      timestamp INTEGER
    )
  `;
  static readonly TRANSACTIONS = `
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      type TEXT,
      amount INTEGER,
      reference_id TEXT,
      timestamp INTEGER
    )
  `;
  static readonly PLAYER_DECKS = `
    CREATE TABLE IF NOT EXISTS player_decks (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      name TEXT,
      game_type TEXT,
      format TEXT,
      cards TEXT,
      created_at INTEGER
    )
  `;
}
