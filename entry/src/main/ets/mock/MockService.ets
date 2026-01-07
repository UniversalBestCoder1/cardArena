import http from '@ohos.net.http';
import relationalStore from '@ohos.data.relationalStore';
import DBHelper, { DeleteCriteria } from '../common/DBHelper';
import { Card, GameType } from '../model/Card';
import { Tournament, TournamentStatus, OrganizerType, YGOFormat, MTGFormat } from '../model/Tournament';
import { RentableDeck, DeckComposition } from '../model/RentableDeck';
import { User } from '../model/User';
import { ChatMessage } from '../model/Chat';
import { Seat } from '../model/Seat';
import { SingleCard } from '../model/Inventory';
import { Deck, DeckCards } from '../model/PlayerDeck';
import { DeckPost, DeckComment } from '../model/SocialDeck'; // Moved up
import { TradeListing, TradeType } from '../model/Trade';
import { FinancialReport } from '../model/Finance'; // [New]

// YGOCDB API 接口
interface YGOCDBRaw {
  id: number;
  cn_name: string;
  type: string;
  text: string;
  atk?: number;
  def?: number;
  attribute?: string;
  race?: string;
}

interface YGOCDBResponse {
  result: YGOCDBRaw[];
}

// Scryfall (MTG) API 接口
interface MTGPrice {
  usd?: string;
}

interface MTGImageUris {
  normal: string;
}

interface MTGCardFace {
  image_uris?: MTGImageUris;
  oracle_text?: string;
}

interface MTGCardRaw {
  id: string;
  name: string;
  printed_name?: string;
  type_line: string;
  rarity: string;
  oracle_text?: string;
  prices?: MTGPrice;
  image_uris?: MTGImageUris;
  card_faces?: MTGCardFace[];
}

interface MTGResponse {
  data: MTGCardRaw[];
}

export class MockService {
  // ... existing methods ...

  // --- Trade Board ---
  static async getTradeListings(): Promise<TradeListing[]> {
    const rs = await DBHelper.query('trade_listings');
    if (!rs) return [];
    
    const list: TradeListing[] = [];
    while (rs.goToNextRow()) {
      list.push({
        id: rs.getString(rs.getColumnIndex('id')),
        userId: rs.getString(rs.getColumnIndex('user_id')),
        username: 'Trader_' + rs.getString(rs.getColumnIndex('user_id')).substr(0,4),
        type: rs.getString(rs.getColumnIndex('type')) as TradeType,
        gameType: rs.getString(rs.getColumnIndex('game_type')),
        cardName: rs.getString(rs.getColumnIndex('card_name')),
        price: rs.getLong(rs.getColumnIndex('price')),
        description: rs.getString(rs.getColumnIndex('description')),
        status: rs.getLong(rs.getColumnIndex('status')),
        createdAt: rs.getLong(rs.getColumnIndex('created_at'))
      });
    }
    rs.close();
    return list.sort((a,b) => b.createdAt - a.createdAt);
  }

  static async createTradeListing(t: TradeListing): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    await DBHelper.insert('trade_listings', {
      id: t.id,
      user_id: user.id,
      type: t.type,
      game_type: t.gameType,
      card_name: t.cardName,
      price: t.price,
      description: t.description,
      status: 0,
      created_at: t.createdAt
    });
    return true;
  }

  // --- Deck Hub ---
  static async getDeckPosts(): Promise<DeckPost[]> {
    const rs = await DBHelper.query('deck_posts');
    if (!rs) return [];
    
    const list: DeckPost[] = [];
    while (rs.goToNextRow()) {
      let deck = null;
      try {
        deck = JSON.parse(rs.getString(rs.getColumnIndex('deck_json')));
      } catch(e) {}
      
      if (deck) {
        list.push({
          id: rs.getString(rs.getColumnIndex('id')),
          userId: rs.getString(rs.getColumnIndex('user_id')),
          // In real app, join users table for username. Mocking for speed:
          username: 'Duelist_' + rs.getString(rs.getColumnIndex('user_id')).substr(0,4),
          deck: deck,
          title: rs.getString(rs.getColumnIndex('title')),
          description: rs.getString(rs.getColumnIndex('description')),
          likes: rs.getLong(rs.getColumnIndex('likes')),
          createdAt: rs.getLong(rs.getColumnIndex('created_at'))
        });
      }
    }
    rs.close();
    return list.sort((a,b) => b.createdAt - a.createdAt);
  }

  static async publishDeck(deck: Deck, title: string, desc: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    await DBHelper.insert('deck_posts', {
      id: `post_${new Date().getTime()}`,
      user_id: user.id,
      deck_json: JSON.stringify(deck),
      title: title,
      description: desc,
      likes: 0,
      created_at: new Date().getTime()
    });
    return true;
  }
  
  // --- 用户认证 ---
  
  static async login(username: string, password: string): Promise<User | null> {
    const rs = await DBHelper.query('users');
    let user: User | null = null;
    
    if (rs) {
      while (rs.goToNextRow()) {
        const uName = rs.getString(rs.getColumnIndex('username'));
        const uPass = rs.getString(rs.getColumnIndex('password'));
        if (uName === username && uPass === password) {
          let refProfile = undefined;
          try {
            const rp = rs.getString(rs.getColumnIndex('referee_profile'));
            if (rp) refProfile = JSON.parse(rp);
          } catch (e) {}

          user = {
            id: rs.getString(rs.getColumnIndex('id')),
            username: uName,
            role: rs.getString(rs.getColumnIndex('role')) as 'MANAGER' | 'STAFF' | 'PLAYER',
            wallet_balance: rs.getLong(rs.getColumnIndex('wallet_balance')) || 0,
            refereeProfile: refProfile
          };
          break;
        }
      }
      rs.close();
    }
    
    if (user) {
      AppStorage.SetOrCreate('currentUser', user);
      AppStorage.SetOrCreate('userRole', user.role);
    }
    return user;
  }

  static async register(username: string, password: string, role: string): Promise<boolean> {
    const rs = await DBHelper.query('users');
    if (rs) {
      while (rs.goToNextRow()) {
        if (rs.getString(rs.getColumnIndex('username')) === username) {
          rs.close();
          return false;
        }
      }
      rs.close();
    }

    const newUser: relationalStore.ValuesBucket = {
      id: `u_${new Date().getTime()}`,
      username: username,
      password: password,
      role: role,
      wallet_balance: 0
    };
    await DBHelper.insert('users', newUser);
    return true;
  }

  static logout() {
    AppStorage.SetOrCreate('currentUser', null);
    AppStorage.SetOrCreate('userRole', null);
  }

  static getCurrentUser(): User | null {
    return AppStorage.Get('currentUser') || null;
  }

  static async getAvailableReferees(): Promise<User[]> {
    const rs = await DBHelper.query('users');
    if (!rs) return [];
    
    const list: User[] = [];
    while (rs.goToNextRow()) {
      const role = rs.getString(rs.getColumnIndex('role'));
      const profileStr = rs.getString(rs.getColumnIndex('referee_profile'));
      
      if (role === 'STAFF' && profileStr) {
        try {
           list.push({
            id: rs.getString(rs.getColumnIndex('id')),
            username: rs.getString(rs.getColumnIndex('username')),
            role: 'STAFF',
            wallet_balance: rs.getLong(rs.getColumnIndex('wallet_balance')),
            refereeProfile: JSON.parse(profileStr)
           });
        } catch (e) {}
      }
    }
    rs.close();
    return list;
  }

  static async updateLfgStatus(status: 'IDLE' | 'LFG_YGO' | 'LFG_MTG' | 'LFG_EDH', message: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    await DBHelper.update('users', {
      lfg_status: status,
      lfg_message: message
    }, user.id);
    
    // Update local cache
    user.lfgStatus = status;
    user.lfgMessage = message;
    AppStorage.SetOrCreate('currentUser', user);
    
    return true;
  }

  static async getOnlinePlayers(): Promise<User[]> {
    const rs = await DBHelper.query('users');
    if (!rs) return [];
    
    const list: User[] = [];
    while (rs.goToNextRow()) {
      const lfg = rs.getString(rs.getColumnIndex('lfg_status'));
      if (lfg && lfg !== 'IDLE') {
        try {
           list.push({
            id: rs.getString(rs.getColumnIndex('id')),
            username: rs.getString(rs.getColumnIndex('username')),
            role: rs.getString(rs.getColumnIndex('role')) as 'MANAGER' | 'STAFF' | 'PLAYER',
            wallet_balance: rs.getLong(rs.getColumnIndex('wallet_balance')),
            lfgStatus: lfg as 'IDLE' | 'LFG_YGO' | 'LFG_MTG' | 'LFG_EDH',
            lfgMessage: rs.getString(rs.getColumnIndex('lfg_message'))
           });
        } catch (e) {}
      }
    }
    rs.close();
    return list;
  }

  // --- 钱包与交易 ---

  static async getUserBalance(): Promise<number> {
    const user = MockService.getCurrentUser();
    if (!user) return 0;
    
    const rs = await DBHelper.query('users');
    let balance = 0;
    if (rs) {
      while (rs.goToNextRow()) {
        if (rs.getString(rs.getColumnIndex('id')) === user.id) {
          balance = rs.getLong(rs.getColumnIndex('wallet_balance'));
          break;
        }
      }
      rs.close();
    }
    
    if (user) {
      user.wallet_balance = balance;
      AppStorage.SetOrCreate('currentUser', user);
    }
    return balance;
  }

  static async rechargeWallet(amount: number): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    const newBalance = (user.wallet_balance || 0) + amount;
    await DBHelper.update('users', { wallet_balance: newBalance }, user.id);
    
    await DBHelper.insert('transactions', {
      user_id: user.id,
      type: 'DEPOSIT',
      amount: amount,
      reference_id: 'recharge',
      timestamp: new Date().getTime()
    });
    
    await MockService.getUserBalance(); 
    return true;
  }

  static async getFinancialReport(): Promise<FinancialReport> {
    const rs = await DBHelper.query('transactions');
    let total = 0;
    let incomeTournament = 0;
    let incomeRental = 0; 
    let incomeOther = 0;

    if (rs) {
      while (rs.goToNextRow()) {
        const type = rs.getString(rs.getColumnIndex('type'));
        const amount = rs.getLong(rs.getColumnIndex('amount'));
        
        if (type === 'TOURNAMENT_FEE') {
          total += amount;
          incomeTournament += amount;
        } else if (type === 'REFUND') {
          total += amount; 
          incomeTournament += amount;
        }
      }
      rs.close();
    }
    
    return {
      totalRevenue: total,
      byType: {
        tournament: incomeTournament,
        rental: incomeRental,
        other: incomeOther
      }
    };
  }

  // --- 聊天功能 ---

  static async getChatMessages(): Promise<ChatMessage[]> {
    const user = MockService.getCurrentUser();
    const rs = await DBHelper.query('chat_messages');
    if (!rs) return [];

    const list: ChatMessage[] = [];
    while (rs.goToNextRow()) {
      const msg: ChatMessage = {
        id: rs.getLong(rs.getColumnIndex('id')),
        sender_id: rs.getString(rs.getColumnIndex('sender_id')),
        sender_name: rs.getString(rs.getColumnIndex('sender_name')),
        sender_role: rs.getString(rs.getColumnIndex('sender_role')),
        receiver_id: rs.getString(rs.getColumnIndex('receiver_id')),
        content: rs.getString(rs.getColumnIndex('content')),
        timestamp: rs.getLong(rs.getColumnIndex('timestamp'))
      };

      if (!msg.receiver_id || (user && (msg.sender_id === user.id || msg.receiver_id === user.id))) {
        list.push(msg);
      }
    }
    rs.close();
    return list.sort((a, b) => a.timestamp - b.timestamp);
  }

  static async sendChatMessage(content: string, receiverId: string = ''): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    await DBHelper.insert('chat_messages', {
      sender_id: user.id,
      sender_name: user.username,
      sender_role: user.role,
      receiver_id: receiverId,
      content: content,
      timestamp: new Date().getTime()
    });
    return true;
  }

  // --- 赛事功能 ---

  static async getTournaments(): Promise<Tournament[]> {
    const user = MockService.getCurrentUser();
    const resultSet = await DBHelper.query('tournaments');
    if (!resultSet) return [];

    const joinedIds: string[] = [];
    if (user) {
      const enrollSet = await DBHelper.query('enrollments');
      if (enrollSet) {
        while (enrollSet.goToNextRow()) {
          const tid = enrollSet.getString(enrollSet.getColumnIndex('tournament_id'));
          const uid = enrollSet.getString(enrollSet.getColumnIndex('user_id'));
          if (uid === user.id) {
            joinedIds.push(tid);
          }
        }
        enrollSet.close();
      }
    }
    
    const list: Tournament[] = [];
    while (resultSet.goToNextRow()) {
      const id = resultSet.getString(resultSet.getColumnIndex('id'));
      
      let orgType = resultSet.getString(resultSet.getColumnIndex('organizerType'));
      if (!orgType) orgType = OrganizerType.SHOP;

      let reqRef = 0;
      try {
        reqRef = resultSet.getLong(resultSet.getColumnIndex('requireReferee'));
      } catch (e) {}

      let poster = resultSet.getString(resultSet.getColumnIndex('poster'));
      if (!poster) {
         // Default logic
         const gType = resultSet.getString(resultSet.getColumnIndex('gameType')) as GameType;
         if (gType === GameType.YGO) poster = 'app.media.ygo_poster';
         else if (gType === GameType.MTG) poster = 'app.media.mtg_poster';
      }

      list.push({
        id: id,
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        gameType: resultSet.getString(resultSet.getColumnIndex('gameType')) as GameType,
        format: resultSet.getString(resultSet.getColumnIndex('format')) || 'Standard',
        startTime: resultSet.getString(resultSet.getColumnIndex('startTime')),
        status: resultSet.getString(resultSet.getColumnIndex('status')) as TournamentStatus,
        maxPlayers: resultSet.getLong(resultSet.getColumnIndex('maxPlayers')),
        currentPlayers: resultSet.getLong(resultSet.getColumnIndex('currentPlayers')),
        entryFee: resultSet.getLong(resultSet.getColumnIndex('entryFee')),
        location: resultSet.getString(resultSet.getColumnIndex('location')),
        description: resultSet.getString(resultSet.getColumnIndex('description')),
        organizerType: orgType as OrganizerType,
        organizerName: resultSet.getString(resultSet.getColumnIndex('organizerName')) || '官方',
        organizerId: resultSet.getString(resultSet.getColumnIndex('organizerId')),
        poster: poster,
        requireReferee: reqRef === 1,
        allowedDecks: resultSet.getString(resultSet.getColumnIndex('allowedDecks')) || '无限制',
        isJoined: joinedIds.includes(id) 
      });
    }
    resultSet.close();
    return list;
  }

  static async joinTournament(tournamentId: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    const enrolls = await DBHelper.query('enrollments');
    let exists = false;
    if (enrolls) {
      while (enrolls.goToNextRow()) {
        if (enrolls.getString(enrolls.getColumnIndex('tournament_id')) === tournamentId &&
            enrolls.getString(enrolls.getColumnIndex('user_id')) === user.id) {
          exists = true;
          break;
        }
      }
      enrolls.close();
    }
    if (exists) return true;

    const tourneys = await DBHelper.query('tournaments');
    let fee = 0;
    let currentCount = 0;
    let maxPlayers = 999; // Default
    let organizerId = '';

    if (tourneys) {
      while (tourneys.goToNextRow()) {
        if (tourneys.getString(tourneys.getColumnIndex('id')) === tournamentId) {
          fee = tourneys.getLong(tourneys.getColumnIndex('entryFee'));
          currentCount = tourneys.getLong(tourneys.getColumnIndex('currentPlayers'));
          maxPlayers = tourneys.getLong(tourneys.getColumnIndex('maxPlayers'));
          organizerId = tourneys.getString(tourneys.getColumnIndex('organizerId'));
          break;
        }
      }
      tourneys.close();
    }

    // [Fix] Check if full
    if (currentCount >= maxPlayers) {
      console.warn('[MockService] Tournament is full:', tournamentId);
      return false;
    }

    // [New] Organizer joins for free
    if (user.id === organizerId) {
      console.info(`[MockService] Organizer ${user.username} joining their own tournament for FREE.`);
      fee = 0;
    }

    const currentBalance = await MockService.getUserBalance();
    if (currentBalance < fee) {
      return false; 
    }

    if (fee > 0) {
      await DBHelper.update('users', { wallet_balance: currentBalance - fee }, user.id);
      await DBHelper.insert('transactions', {
        user_id: user.id,
        type: 'TOURNAMENT_FEE',
        amount: fee, 
        reference_id: tournamentId,
        timestamp: new Date().getTime()
      });
    }

    await DBHelper.insert('enrollments', { tournament_id: tournamentId, user_id: user.id });
    
    await DBHelper.update('tournaments', { currentPlayers: currentCount + 1 }, tournamentId);
    
    await MockService.getUserBalance(); 
    return true;
  }

  static async cancelTournament(tournamentId: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;

    let enrollId = -1;
    const enrolls = await DBHelper.query('enrollments');
    if (enrolls) {
      while (enrolls.goToNextRow()) {
        if (enrolls.getString(enrolls.getColumnIndex('tournament_id')) === tournamentId &&
            enrolls.getString(enrolls.getColumnIndex('user_id')) === user.id) {
          enrollId = enrolls.getLong(enrolls.getColumnIndex('id'));
          break;
        }
      }
      enrolls.close();
    }
    if (enrollId === -1) return false; 

    const tourneys = await DBHelper.query('tournaments');
    let fee = 0;
    let currentCount = 0;
    if (tourneys) {
      while (tourneys.goToNextRow()) {
        if (tourneys.getString(tourneys.getColumnIndex('id')) === tournamentId) {
          fee = tourneys.getLong(tourneys.getColumnIndex('entryFee'));
          currentCount = tourneys.getLong(tourneys.getColumnIndex('currentPlayers'));
          break;
        }
      }
      tourneys.close();
    }

    const currentBalance = await MockService.getUserBalance();
    await DBHelper.update('users', { wallet_balance: currentBalance + fee }, user.id);
    await DBHelper.insert('transactions', {
      user_id: user.id,
      type: 'REFUND',
      amount: -fee, 
      reference_id: tournamentId,
      timestamp: new Date().getTime()
    });

    await DBHelper.delete('enrollments', { field: 'id', value: enrollId.toString() });

    await DBHelper.update('tournaments', { currentPlayers: Math.max(0, currentCount - 1) }, tournamentId);

    await MockService.getUserBalance();
    return true;
  }

  static async createTournament(t: Tournament): Promise<boolean> {
    // [Updated] Player tournaments start as PENDING_APPROVAL
    const initialStatus = t.organizerType === OrganizerType.PLAYER ? TournamentStatus.PENDING_APPROVAL : t.status;
    
    let poster = t.poster;
    if (!poster) {
       if (t.gameType === GameType.YGO) poster = 'app.media.ygo_poster';
       else if (t.gameType === GameType.MTG) poster = 'app.media.mtg_poster';
    }

    const values: relationalStore.ValuesBucket = {
      id: t.id,
      title: t.title,
      gameType: t.gameType,
      format: t.format,
      startTime: t.startTime,
      status: initialStatus,
      maxPlayers: t.maxPlayers,
      currentPlayers: t.currentPlayers,
      entryFee: t.entryFee,
      location: t.location,
      description: t.description,
      organizerType: t.organizerType,
      organizerName: t.organizerName,
      organizerId: t.organizerId || null,
      poster: poster || null,
      requireReferee: t.requireReferee ? 1 : 0,
      allowedDecks: t.allowedDecks,
      refereeId: t.refereeId || null
    };
    
    await DBHelper.insert('tournaments', values);
    return true;
  }

  static async deleteTournament(id: string): Promise<boolean> {
    await DBHelper.delete('tournaments', { field: 'id', value: id });
    return true;
  }

  static async approveTournament(id: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (user?.role !== 'MANAGER') return false;
    
    await DBHelper.update('tournaments', { status: TournamentStatus.REGISTERING }, id);
    return true;
  }

  static async rejectTournament(id: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (user?.role !== 'MANAGER') return false;

    await DBHelper.update('tournaments', { status: TournamentStatus.REJECTED }, id);
    return true;
  }

  static async getTournamentPlayers(tournamentId: string): Promise<User[]> {
    const enrolls = await DBHelper.query('enrollments');
    const userIds: string[] = [];
    if (enrolls) {
      while (enrolls.goToNextRow()) {
        if (enrolls.getString(enrolls.getColumnIndex('tournament_id')) === tournamentId) {
          userIds.push(enrolls.getString(enrolls.getColumnIndex('user_id')));
        }
      }
      enrolls.close();
    }

    if (userIds.length === 0) return [];

    const allUsers: User[] = [];
    const uRs = await DBHelper.query('users');
    if (uRs) {
      while (uRs.goToNextRow()) {
        allUsers.push({
           id: uRs.getString(uRs.getColumnIndex('id')),
           username: uRs.getString(uRs.getColumnIndex('username')),
           role: uRs.getString(uRs.getColumnIndex('role')) as 'MANAGER' | 'STAFF' | 'PLAYER',
           wallet_balance: uRs.getLong(uRs.getColumnIndex('wallet_balance'))
        });
      }
      uRs.close();
    }
    
    return allUsers.filter(u => userIds.includes(u.id));
  }

  static async kickPlayer(tournamentId: string, userId: string): Promise<boolean> {
    const currentUser = MockService.getCurrentUser();
    if (!currentUser) return false;

    // Fetch tournament to check organizer
    const rs = await DBHelper.query('tournaments');
    let t: Tournament | null = null;
    if (rs) {
      while (rs.goToNextRow()) {
        if (rs.getString(rs.getColumnIndex('id')) === tournamentId) {
           t = {
             id: tournamentId,
             organizerType: rs.getString(rs.getColumnIndex('organizerType')) as OrganizerType,
             // ... other fields not strictly needed for this check
           } as Tournament;
           break;
        }
      }
      rs.close();
    }
    
    if (!t) return false;

    // Rule: Manager cannot reject/kick players from Player-organized tournaments
    if (currentUser.role === 'MANAGER' && t.organizerType === OrganizerType.PLAYER) {
      console.warn('Manager cannot kick players from player-organized tournament');
      return false;
    }
    
    // Only Manager or the Organizer (logic simplified here) can kick
    // For now, assuming if passed the check above, and is manager, it's allowed. 
    // Or if currentUser is the organizer (not fully implemented user check).
    if (currentUser.role !== 'MANAGER') {
       // Allow if user is the organizer? (Skip for now based on prompt focus)
       return false;
    }

    // Perform Kick (Cancel)
    // Reuse cancel logic but for specific user
    // We need a specific "force cancel" method or adapt existing one.
    // Existing cancelTournament uses current user. We need "kickUserFromTournament".
    
    return await MockService.forceKickUser(tournamentId, userId);
  }

  private static async forceKickUser(tournamentId: string, userId: string): Promise<boolean> {
    // Similar to cancelTournament but for specific userId
    let enrollId = -1;
    const enrolls = await DBHelper.query('enrollments');
    if (enrolls) {
      while (enrolls.goToNextRow()) {
        if (enrolls.getString(enrolls.getColumnIndex('tournament_id')) === tournamentId &&
            enrolls.getString(enrolls.getColumnIndex('user_id')) === userId) {
          enrollId = enrolls.getLong(enrolls.getColumnIndex('id'));
          break;
        }
      }
      enrolls.close();
    }
    if (enrollId === -1) return false; 

    const tourneys = await DBHelper.query('tournaments');
    let fee = 0;
    let currentCount = 0;
    if (tourneys) {
      while (tourneys.goToNextRow()) {
        if (tourneys.getString(tourneys.getColumnIndex('id')) === tournamentId) {
          fee = tourneys.getLong(tourneys.getColumnIndex('entryFee'));
          currentCount = tourneys.getLong(tourneys.getColumnIndex('currentPlayers'));
          break;
        }
      }
      tourneys.close();
    }

    // Refund
    const uRs = await DBHelper.query('users');
    let currentBalance = 0;
    if(uRs) {
        while(uRs.goToNextRow()) {
            if(uRs.getString(uRs.getColumnIndex('id')) === userId) {
                currentBalance = uRs.getLong(uRs.getColumnIndex('wallet_balance'));
                break;
            }
        }
        uRs.close();
    }

    await DBHelper.update('users', { wallet_balance: currentBalance + fee }, userId);
    await DBHelper.insert('transactions', {
      user_id: userId,
      type: 'REFUND_KICK',
      amount: -fee, 
      reference_id: tournamentId,
      timestamp: new Date().getTime()
    });

    await DBHelper.delete('enrollments', { field: 'id', value: enrollId.toString() });
    await DBHelper.update('tournaments', { currentPlayers: Math.max(0, currentCount - 1) }, tournamentId);

    return true;
  }

  // --- Friends & Users ---
  
  static async searchUsers(keyword: string): Promise<User[]> {
    const rs = await DBHelper.query('users');
    const list: User[] = [];
    if (rs) {
      while (rs.goToNextRow()) {
        const uname = rs.getString(rs.getColumnIndex('username'));
        if (uname.includes(keyword)) {
           list.push({
             id: rs.getString(rs.getColumnIndex('id')),
             username: uname,
             role: rs.getString(rs.getColumnIndex('role')) as 'MANAGER' | 'STAFF' | 'PLAYER',
             wallet_balance: rs.getLong(rs.getColumnIndex('wallet_balance'))
           });
        }
      }
      rs.close();
    }
    return list;
  }

  static async addFriend(friendId: string): Promise<boolean> {
    const user = MockService.getCurrentUser();
    if (!user) return false;
    
    // Check if exists
    const rs = await DBHelper.query('friends');
    let exists = false;
    if (rs) {
      while(rs.goToNextRow()) {
        if (rs.getString(rs.getColumnIndex('user_id')) === user.id && 
            rs.getString(rs.getColumnIndex('friend_id')) === friendId) {
          exists = true;
          break;
        }
      }
      rs.close();
    }
    if (exists) return true;

    await DBHelper.insert('friends', {
      user_id: user.id,
      friend_id: friendId,
      created_at: new Date().getTime()
    });
    return true;
  }

  static async getFriends(): Promise<User[]> {
    const user = MockService.getCurrentUser();
    if (!user) return [];

    const rs = await DBHelper.query('friends');
    const friendIds: string[] = [];
    if (rs) {
      while (rs.goToNextRow()) {
        if (rs.getString(rs.getColumnIndex('user_id')) === user.id) {
          friendIds.push(rs.getString(rs.getColumnIndex('friend_id')));
        }
      }
      rs.close();
    }
    
    if (friendIds.length === 0) return [];

    // Fetch user details
    const allUsers = await MockService.searchUsers(''); // GetAll
    return allUsers.filter(u => friendIds.includes(u.id));
  }

  static async getRecentConversations(): Promise<User[]> {
    const user = MockService.getCurrentUser();
    if (!user) return [];

    const rs = await DBHelper.query('chat_messages');
    const contactIds = new Set<string>();
    
    if (rs) {
      while (rs.goToNextRow()) {
        const sId = rs.getString(rs.getColumnIndex('sender_id'));
        const rId = rs.getString(rs.getColumnIndex('receiver_id'));
        
        if (sId === user.id && rId) contactIds.add(rId);
        if (rId === user.id) contactIds.add(sId);
      }
      rs.close();
    }
    
    if (contactIds.size === 0) return [];
    
    const allUsers = await MockService.searchUsers('');
    return allUsers.filter(u => contactIds.has(u.id));
  }

  // --- 库存/卡组功能 ---

  static async getRentableDecks(): Promise<RentableDeck[]> {
    const currentUser = MockService.getCurrentUser();
    const currentUserId = currentUser ? currentUser.id : '';

    const rentedDeckIds: string[] = [];
    if (currentUserId) {
      const rentalRs = await DBHelper.query('rentals');
      if (rentalRs) {
        while (rentalRs.goToNextRow()) {
          const rStatus = rentalRs.getLong(rentalRs.getColumnIndex('status'));
          const rUser = rentalRs.getString(rentalRs.getColumnIndex('user_id'));
          const rDeckId = rentalRs.getString(rentalRs.getColumnIndex('deck_id'));
          
          if (rStatus === 0 && rUser === currentUserId) {
            rentedDeckIds.push(rDeckId);
          }
        }
        rentalRs.close();
      }
    }

    const resultSet = await DBHelper.query('decks');
    if (!resultSet) return [];

    const list: RentableDeck[] = [];
    while (resultSet.goToNextRow()) {
      const id = resultSet.getString(resultSet.getColumnIndex('id'));
      const tagsStr = resultSet.getString(resultSet.getColumnIndex('tags'));
      const compStr = resultSet.getString(resultSet.getColumnIndex('composition'));

      list.push({
        id: id,
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        gameType: resultSet.getString(resultSet.getColumnIndex('gameType')) as GameType,
        coverImage: resultSet.getString(resultSet.getColumnIndex('cover_image')) || 'app.media.mtga_icon',
        rentalFeePerHour: resultSet.getLong(resultSet.getColumnIndex('rentalFeePerHour')),
        stock: resultSet.getLong(resultSet.getColumnIndex('stock')),
        description: resultSet.getString(resultSet.getColumnIndex('description')),
        tags: tagsStr ? JSON.parse(tagsStr) : [],
        composition: compStr ? JSON.parse(compStr) : undefined,
        deposit: resultSet.getLong(resultSet.getColumnIndex('deposit')),
        isRentedByMe: rentedDeckIds.includes(id) 
      });
    }
    resultSet.close();
    return list;
  }

  static async rentDeck(deckId: string): Promise<boolean> {
    const currentUser = MockService.getCurrentUser();
    if (!currentUser) return false;

    const decks = await MockService.getRentableDecks();
    const target = decks.find(d => d.id === deckId);
    
    if (!target || target.stock <= 0) return false;
    if (target.isRentedByMe) return false;

    const deposit = target.deposit || 0;
    const currentBalance = await MockService.getUserBalance();
    if (currentBalance < deposit) return false;

    await DBHelper.update('users', { wallet_balance: currentBalance - deposit }, currentUser.id);
    await DBHelper.insert('transactions', {
      user_id: currentUser.id,
      type: 'DEPOSIT_DEDUCT',
      amount: -deposit,
      reference_id: deckId,
      timestamp: new Date().getTime()
    });

    await DBHelper.update('decks', { stock: target.stock - 1 }, deckId);
    await DBHelper.insert('rentals', { 
      deck_id: deckId, 
      rent_time: new Date().getTime(), 
      status: 0,
      user_id: currentUser.id
    });
    
    await MockService.getUserBalance();
    return true;
  }

  static async returnDeck(deckId: string): Promise<boolean> {
    const currentUser = MockService.getCurrentUser();
    if (!currentUser) return false;

    const decks = await MockService.getRentableDecks();
    const target = decks.find(d => d.id === deckId);
    if (!target) return false;

    const rs = await DBHelper.query('rentals');
    let rentalId = -1;
    let rentTime = 0;
    
    if (rs) {
      while (rs.goToNextRow()) {
        const dId = rs.getString(rs.getColumnIndex('deck_id'));
        const st = rs.getLong(rs.getColumnIndex('status'));
        const uId = rs.getString(rs.getColumnIndex('user_id'));
        
        if (dId === deckId && st === 0 && uId === currentUser.id) {
          rentalId = rs.getLong(rs.getColumnIndex('id'));
          rentTime = rs.getLong(rs.getColumnIndex('rent_time'));
          break;
        }
      }
      rs.close();
    }

    if (rentalId === -1) return false;

    const now = new Date().getTime();
    const hours = Math.ceil((now - rentTime) / (1000 * 60 * 60)); 
    const fee = Math.max(1, hours) * target.rentalFeePerHour; 
    const deposit = target.deposit || 0;

    const currentBalance = await MockService.getUserBalance();
    const finalRefund = deposit - fee; 
    
    await DBHelper.update('users', { wallet_balance: currentBalance + finalRefund }, currentUser.id);
    
    await DBHelper.insert('transactions', {
      user_id: currentUser.id,
      type: 'DEPOSIT_REFUND',
      amount: deposit,
      reference_id: deckId,
      timestamp: now
    });
    await DBHelper.insert('transactions', {
      user_id: currentUser.id,
      type: 'RENTAL_FEE',
      amount: -fee,
      reference_id: deckId,
      timestamp: now
    });

    await DBHelper.update('decks', { stock: target.stock + 1 }, deckId);
    
    await DBHelper.delete('rentals', { field: 'id', value: rentalId.toString() });
    await DBHelper.insert('rentals', { 
      deck_id: deckId, 
      rent_time: now, 
      status: 1,
      user_id: currentUser.id 
    });
    
    await MockService.getUserBalance();
    return true;
  }

  // --- Inventory & Master DB ---
  static async searchMasterDatabase(keyword: string): Promise<Record<string, Object>[]> {
    if (!keyword) return [];
    
    // 1. Search Local
    const rs = await DBHelper.query('card_database');
    const localList: Record<string, Object>[] = [];
    if (rs) {
      while (rs.goToNextRow()) {
        const name = rs.getString(rs.getColumnIndex('name'));
        if (name.toLowerCase().includes(keyword.toLowerCase()) || keyword === '*') {
          const item: Record<string, Object> = {
            'id': rs.getString(rs.getColumnIndex('id')),
            'name': name,
            'game_type': rs.getString(rs.getColumnIndex('game_type')),
            'card_code': rs.getString(rs.getColumnIndex('card_code')),
            'rarity': rs.getString(rs.getColumnIndex('rarity'))
          };
          localList.push(item);
        }
      }
      rs.close();
    }

    // 2. If not enough results, fetch remote
    if (localList.length < 5 && keyword !== '*') {
       try {
         // Parallel search YGO and MTG
         const results = await Promise.all([
            MockService.searchYGO(keyword),
            MockService.searchMTG(keyword)
         ]);
         const ygoRes = results[0];
         const mtgRes = results[1];
         
         const remoteCards = [...ygoRes, ...mtgRes];
         
         for (const card of remoteCards) {
            // Check if exists locally by name (simple check)
            const exists = localList.find(l => l['name'] === card.name);
            if (!exists) {
               // Add to DB
               const newId = `master_${new Date().getTime()}_${Math.floor(Math.random()*1000)}`;
               await DBHelper.insert('card_database', {
                 id: newId,
                 name: card.name,
                 game_type: card.gameType,
                 card_code: 'API-NET', // Placeholder
                 rarity: card.rarity || 'N/A',
                 type: card.type
               });
               
               // Add to result list
               localList.push({
                 'id': newId,
                 'name': card.name,
                 'game_type': card.gameType,
                 'card_code': 'API-NET',
                 'rarity': card.rarity || 'N/A'
               });
            }
         }
       } catch (e) {
         console.error('Remote search failed: ' + JSON.stringify(e));
       }
    }

    return localList;
  }

  static async addSingleFromMaster(masterCard: Record<string, Object>, stock: number, price: number): Promise<boolean> {
    const newId = `s_${new Date().getTime()}`;
    await DBHelper.insert('singles', {
      id: newId,
      name: masterCard['name'] as string,
      card_code: masterCard['card_code'] as string,
      rarity: masterCard['rarity'] as string,
      stock: stock,
      price: price,
      is_proxy: 0
    });
    return true;
  }

  static async getSingles(): Promise<SingleCard[]> {
    const resultSet = await DBHelper.query('singles');
    if (!resultSet) return [];

    const list: SingleCard[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        card_code: resultSet.getString(resultSet.getColumnIndex('card_code')),
        rarity: resultSet.getString(resultSet.getColumnIndex('rarity')),
        stock: resultSet.getLong(resultSet.getColumnIndex('stock')),
        price: resultSet.getLong(resultSet.getColumnIndex('price')),
        is_proxy: resultSet.getLong(resultSet.getColumnIndex('is_proxy')) === 1
      });
    }
    resultSet.close();
    return list;
  }

  // [新增] 玩家自建卡组管理
  static async getPlayerDecks(): Promise<Deck[]> {
    console.info('[MockService] getPlayerDecks called');
    const user = MockService.getCurrentUser();
    if (!user) {
      console.warn('[MockService] No current user');
      return [];
    }

    const rs = await DBHelper.query('player_decks');
    if (!rs) {
      console.warn('[MockService] player_decks query returned null');
      return [];
    }

    const list: Deck[] = [];
    while (rs.goToNextRow()) {
      const uId = rs.getString(rs.getColumnIndex('user_id'));
      if (uId === user.id) {
        let cards: DeckCards = { main: [], extra: [], side: [] };
        try {
          const cardsStr = rs.getString(rs.getColumnIndex('cards'));
          if (cardsStr) cards = JSON.parse(cardsStr);
        } catch (e) {
          console.error('[MockService] JSON parse error for deck cards:', e);
        }

        list.push({
          id: rs.getString(rs.getColumnIndex('id')),
          name: rs.getString(rs.getColumnIndex('name')),
          gameType: rs.getString(rs.getColumnIndex('game_type')),
          format: rs.getString(rs.getColumnIndex('format')),
          cards: cards,
          createdAt: rs.getLong(rs.getColumnIndex('created_at'))
        });
      }
    }
    rs.close();
    console.info(`[MockService] Found ${list.length} decks for user ${user.username}`);
    return list;
  }

  static async createPlayerDeck(deck: Deck): Promise<boolean> {
    console.info('[MockService] createPlayerDeck called:', JSON.stringify(deck));
    const user = MockService.getCurrentUser();
    if (!user) return false;

    const rowId = await DBHelper.insert('player_decks', {
      id: deck.id,
      user_id: user.id,
      name: deck.name,
      game_type: deck.gameType || '', 
      format: deck.format || '',      
      cards: JSON.stringify(deck.cards),
      created_at: deck.createdAt
    });
    console.info('[MockService] createPlayerDeck result rowId:', rowId);
    return rowId >= 0;
  }

  static async updatePlayerDeck(deck: Deck): Promise<boolean> {
    await DBHelper.update('player_decks', {
      name: deck.name,
      game_type: deck.gameType || '', 
      format: deck.format || '',      
      cards: JSON.stringify(deck.cards)
    }, deck.id);
    return true;
  }

  static async deletePlayerDeck(deckId: string): Promise<boolean> {
    await DBHelper.delete('player_decks', { field: 'id', value: deckId });
    return true;
  }

  // --- 其他功能 ---

  static async getSeats(): Promise<Seat[]> {
    const layout: Seat[] = [];
    for (let i = 1; i <= 8; i++) {
      layout.push({ id: `A${i}`, label: `A${i}`, isBooked: false, type: 'COMMON' });
    }
    layout.push({ id: 'V1', label: 'VIP 1', isBooked: false, type: 'VIP' });
    layout.push({ id: 'V2', label: 'VIP 2', isBooked: false, type: 'VIP' });

    const resultSet = await DBHelper.query('seat_bookings');
    const bookedIds: string[] = [];
    if (resultSet) {
      while (resultSet.goToNextRow()) {
        bookedIds.push(resultSet.getString(resultSet.getColumnIndex('seat_id')));
      }
      resultSet.close();
    }
    
    return layout.map((s: Seat) => {
      const seat: Seat = {
        id: s.id,
        label: s.label,
        isBooked: bookedIds.includes(s.id),
        type: s.type
      };
      return seat;
    });
  }

  static async bookSeat(seatId: string): Promise<boolean> {
    const resultSet = await DBHelper.query('seat_bookings');
    let isBooked = false;
    if (resultSet) {
      while (resultSet.goToNextRow()) {
        if (resultSet.getString(resultSet.getColumnIndex('seat_id')) === seatId) {
          isBooked = true;
          break;
        }
      }
      resultSet.close();
    }

    if (isBooked) {
      return false;
    }

    await DBHelper.insert('seat_bookings', {
      seat_id: seatId,
      book_date: new Date().toISOString().split('T')[0],
      user_id: 'current_user'
    });
    return true;
  }

  static async searchCards(keyword: string, gameType: GameType = GameType.YGO): Promise<Card[]> {
    if (!keyword) {
       return [{
          id: 'mock1',
          name: '示例：青眼白龙',
          type: '通常怪兽',
          rarity: 'UR',
          imageUrl: 'app.media.mtga_icon',
          priceMin: 50,
          priceAvg: 100,
          description: '这是本地演示数据，请输入关键词进行真实搜索。',
          gameType: GameType.YGO
       }];
    }
    
    try {
      if (gameType === GameType.YGO) {
        return await MockService.searchYGO(keyword);
      } else {
        return await MockService.searchMTG(keyword);
      }
    } catch (e) {
      console.error('API Error:' + JSON.stringify(e));
      return [];
    }
  }

  private static async searchYGO(keyword: string): Promise<Card[]> {
    const url = `https://ygocdb.com/api/v0/?search=${encodeURIComponent(keyword)}`;
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, { method: http.RequestMethod.GET, readTimeout: 5000 });
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as YGOCDBResponse;
        const list = result.result;
        if (list && list.length > 0) {
          return list.slice(0, 15).map((item: YGOCDBRaw) => {
            const cardId = item.id;
            return {
              id: cardId.toString(),
              name: item.cn_name,
              type: item.type,
              rarity: 'N/A',
              imageUrl: `https://cdn.233.momobako.com/ygopro/pics/${cardId}.jpg`,
              priceMin: 5,
              priceAvg: 20,
              description: item.text,
              gameType: GameType.YGO,
              atk: item.atk,
              def: item.def,
              attribute: item.attribute,
              race: item.race
            } as Card;
          });
        }
      }
    } catch (e) {
      console.error('YGO API Error: ' + JSON.stringify(e));
    }
    
    if (keyword.includes('青眼')) {
      return [{
          id: '89631139',
          name: '青眼白龙',
          type: '通常怪兽',
          rarity: 'UR',
          imageUrl: 'https://cdn.233.momobako.com/ygopro/pics/89631139.jpg',
          priceMin: 50,
          priceAvg: 120,
          description: '以高攻击力著称的传说之龙。',
          gameType: GameType.YGO,
          atk: 3000,
          def: 2500
      }];
    }
    return [];
  }

  private static async searchMTG(keyword: string): Promise<Card[]> {
    const url = `https://api.scryfall.com/cards/search?q=${encodeURIComponent(keyword)}`;
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, { method: http.RequestMethod.GET });
      if (response.responseCode !== 200) return [];
      const result = JSON.parse(response.result as string) as MTGResponse;
      const list = result.data;
      return list.slice(0, 10).map((item: MTGCardRaw) => {
        const usdStr = item.prices?.usd || '0';
        const cny = parseFloat(usdStr) * 7;
        let img = 'app.media.mtga_icon';
        if (item.image_uris?.normal) {
          img = item.image_uris.normal;
        } else if (item.card_faces && item.card_faces.length > 0 && item.card_faces[0].image_uris?.normal) {
          img = item.card_faces[0].image_uris.normal;
        }
        let desc = item.oracle_text || '';
        if (!desc && item.card_faces && item.card_faces.length > 0) {
          desc = item.card_faces[0].oracle_text || '';
        }
        return {
          id: item.id,
          name: item.printed_name || item.name,
          type: item.type_line,
          rarity: item.rarity.toUpperCase(),
          imageUrl: img,
          priceMin: cny,
          priceAvg: cny,
          description: desc,
          gameType: GameType.MTG
        } as Card;
      });
    } catch (e) {
      return [];
    }
  }
}