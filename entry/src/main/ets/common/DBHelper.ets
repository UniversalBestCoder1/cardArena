import relationalStore from '@ohos.data.relationalStore';
import context from '@ohos.app.ability.common';
import util from '@ohos.util';
import { GameType } from '../model/Card';
import { OrganizerType, YGOFormat, MTGFormat, TournamentStatus } from '../model/Tournament';
import { DDL } from '../db/Schema';

// 定义删除条件接口
export interface DeleteCriteria {
  field: string;
  value: string;
}

interface UserConfig {
  users: relationalStore.ValuesBucket[];
}

class DBHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: context.Context | null = null;
  private initPromise: Promise<void> | null = null; 
  private resolveInit: (() => void) | null = null;
  
  // [New] 用于记录初始化时自动报名的玩家数量
  private initialEnrollmentCount: number = 0;

  private STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'CardArena_v21.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  constructor() {
    this.initPromise = new Promise((resolve) => {
      this.resolveInit = resolve;
    });
  }

  // 初始化数据库
  async init(ctx: context.Context, dbName?: string): Promise<void> {
    const targetName = dbName || 'CardArena_v21.db';
    this.context = ctx;

    // 如果已经初始化且数据库名一致，直接返回
    if (this.rdbStore && this.STORE_CONFIG.name === targetName) {
      if (this.resolveInit) this.resolveInit();
      return;
    }

    // 如果需要切换数据库（例如测试环境），重置 rdbStore
    if (this.rdbStore) {
      console.info(`[DBHelper] Switching DB from ${this.STORE_CONFIG.name} to ${targetName}`);
      this.rdbStore = null;
    }

    this.STORE_CONFIG.name = targetName;

    try {
      console.info(`[DBHelper] Initializing database: ${this.STORE_CONFIG.name}...`);
      this.rdbStore = await relationalStore.getRdbStore(ctx, this.STORE_CONFIG);
      
      // 执行建表 DDL
      await this.rdbStore.executeSql(DDL.TOURNAMENTS);
      await this.rdbStore.executeSql(DDL.DECKS);
      await this.rdbStore.executeSql(DDL.ENROLLMENTS);
      await this.rdbStore.executeSql(DDL.RENTALS);
      await this.rdbStore.executeSql(DDL.SINGLES);
      await this.rdbStore.executeSql(DDL.SEAT_BOOKINGS);
      await this.rdbStore.executeSql(DDL.USERS);
      await this.rdbStore.executeSql(DDL.CHAT_MESSAGES);
      await this.rdbStore.executeSql(DDL.TRANSACTIONS);
      await this.rdbStore.executeSql(DDL.PLAYER_DECKS);
      await this.rdbStore.executeSql(DDL.MATCHES);
      
      // [New] Social Tables
      await this.rdbStore.executeSql(DDL.DECK_POSTS);
      await this.rdbStore.executeSql(DDL.DECK_LIKES);
      await this.rdbStore.executeSql(DDL.DECK_COMMENTS);
      await this.rdbStore.executeSql(DDL.TRADE_LISTINGS);
      
      // [New] Master Database
      await this.rdbStore.executeSql(DDL.CARD_DATABASE);
      // [New] Friends
      await this.rdbStore.executeSql(DDL.FRIENDS);

      await this.seedData();
      console.info('[DBHelper] Database initialized successfully.');

    } catch (e) {
      console.error('[DBHelper] Init failed:', JSON.stringify(e));
      throw new Error(`DB Init Failed: ${JSON.stringify(e)}`);
    } finally {
      if (this.resolveInit) {
        this.resolveInit();
        this.resolveInit = null; // 防止重复调用
      }
    }
  }

  // ... (ensureInit logic) ...
  private async ensureInit() {
    if (!this.rdbStore && this.initPromise) {
      await this.initPromise;
    }
  }

  // 预填数据 (Seeding)
  private async seedData(): Promise<void> {
    const count = await this.queryCount('tournaments');
    if (count > 0) return;

    console.info('DBHelper: Seeding initial data...');

    // A. 插入用户 (From Config)
    if (this.context) {
      try {
        const value = await this.context.resourceManager.getRawFileContent('user_config.json');
        const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        const jsonStr = textDecoder.decodeWithStream(value);
        const config = JSON.parse(jsonStr) as UserConfig;
        
        if (config && config.users) {
           let enrolledCount = 0;
           for (const u of config.users) {
             await this.insert('users', u);
             // [New] 自动让所有 PLAYER 报名 t_ygo_001
             if (u.role === 'PLAYER') {
               await this.insert('enrollments', {
                 tournament_id: 't_ygo_001',
                 user_id: u.id as string
               });
               enrolledCount++;
             }
           }
           this.initialEnrollmentCount = enrolledCount;
           console.info(`DBHelper: Users seeded. Auto-enrolled ${enrolledCount} players to t_ygo_001.`);
        }
      } catch (e) {
        console.error('DBHelper: Failed to load user config: ' + JSON.stringify(e));
      }
    } else {
        console.warn('DBHelper: Context is null, cannot load user config.');
    }

    // B. 插入初始聊天记录
    await this.insert('chat_messages', {
      sender_id: 'system',
      sender_name: 'CardArena 小助手',
      sender_role: 'SYSTEM',
      receiver_id: '', // Public
      content: '欢迎来到 CardArena 决斗者社区！找牌搭子、约战、吹水都在这里~',
      timestamp: new Date().getTime()
    });

    // C. 插入赛事
    const tournaments: relationalStore.ValuesBucket[] = [
      {
        id: 't_ygo_001',
        title: '周六 YGO 积分赛',
        gameType: GameType.YGO,
        format: YGOFormat.OCG_ADVANCED,
        startTime: '2025-12-30 13:30',
        status: TournamentStatus.REGISTERING,
        maxPlayers: 32,
        currentPlayers: this.initialEnrollmentCount || 0, // [New] 使用自动报名的人数
        entryFee: 30,
        location: '对战区 A',
        description: '瑞士轮赛制，使用最新 OCG 禁卡表。',
        organizerType: OrganizerType.SHOP,
        organizerName: 'CardArena 官方',
        requireReferee: 0,
        allowedDecks: '2025.10 OCG 禁止限制卡表'
      },
      {
        id: 't_ygo_002',
        title: '时光回顾赛: Goat Format',
        gameType: GameType.YGO,
        format: YGOFormat.GOAT,
        startTime: '2025-12-31 19:00',
        status: TournamentStatus.REGISTERING,
        maxPlayers: 16,
        currentPlayers: 4,
        entryFee: 20,
        location: '复古区',
        description: '重回 2005！禁止同调、超量、链接。',
        organizerType: OrganizerType.SHOP,
        organizerName: 'CardArena 官方',
        requireReferee: 0,
        allowedDecks: 'Goat Format 卡表 (2005.4)'
      },
      {
        id: 't_ygo_003',
        title: 'Speed Duel 快速决斗',
        gameType: GameType.YGO,
        format: YGOFormat.SPEED_DUEL,
        startTime: '2025-01-01 10:00',
        status: TournamentStatus.REGISTERING,
        maxPlayers: 8,
        currentPlayers: 2,
        entryFee: 15,
        location: '新手区',
        description: '适合新手的快速决斗规则。',
        organizerType: OrganizerType.SHOP,
        organizerName: 'CardArena 官方',
        requireReferee: 0,
        allowedDecks: '仅限 Speed Duel 标记卡片'
      },
      {
        id: 't_mtg_001',
        title: 'FNM 周五认证赛: 标准',
        gameType: GameType.MTG,
        format: MTGFormat.STANDARD,
        startTime: '2025-12-29 19:00',
        status: TournamentStatus.FINISHED,
        maxPlayers: 24,
        currentPlayers: 18,
        entryFee: 50,
        location: '对战区 B',
        description: 'Friday Night Magic! 赢取 FNM 推广包。',
        organizerType: OrganizerType.SHOP,
        organizerName: 'CardArena 官方',
        requireReferee: 1,
        allowedDecks: 'Standard 环境'
      },
      {
        id: 't_mtg_002',
        title: '指挥官之夜 (EDH)',
        gameType: GameType.MTG,
        format: MTGFormat.COMMANDER,
        startTime: '2025-12-30 18:00',
        status: TournamentStatus.RUNNING,
        maxPlayers: 40,
        currentPlayers: 36,
        entryFee: 10,
        location: '休闲大厅',
        description: '多入坑，少互殴。娱乐为主。',
        organizerType: OrganizerType.SHOP,
        organizerName: 'CardArena 官方',
        requireReferee: 0,
        allowedDecks: '遵循 Commander 官方禁牌表'
      },
      {
        id: 't_mtg_003',
        title: '依夏兰轮抽赛 (Draft)',
        gameType: GameType.MTG,
        format: MTGFormat.DRAFT,
        startTime: '2025-12-31 14:00',
        status: TournamentStatus.REGISTERING,
        maxPlayers: 8,
        currentPlayers: 7,
        entryFee: 120,
        location: 'VIP 包厢',
        description: '含 3 包补充包，现场轮抽构筑。',
        organizerType: OrganizerType.SHOP,
        organizerName: 'CardArena 官方',
        requireReferee: 1,
        allowedDecks: '现场开包构筑'
      },
      {
        id: 't_player_001',
        title: '[玩家] 大学生的娱乐赛',
        gameType: GameType.YGO,
        format: YGOFormat.TCG_ADVANCED,
        startTime: '2025-12-30 20:00',
        status: TournamentStatus.REGISTERING,
        maxPlayers: 8,
        currentPlayers: 3,
        entryFee: 5,
        location: '桌号 15-16',
        description: '没什么奖品，就是打着玩。禁止主流。',
        organizerType: OrganizerType.PLAYER,
        organizerName: '决斗者_小明',
        requireReferee: 0,
        allowedDecks: '禁止 T1 主流卡组'
      },
      {
        id: 't_player_002',
        title: '[玩家] 摩登练习赛 (求裁判)',
        gameType: GameType.MTG,
        format: MTGFormat.MODERN,
        startTime: '2025-01-02 13:00',
        status: TournamentStatus.REGISTERING,
        maxPlayers: 12,
        currentPlayers: 8,
        entryFee: 20,
        location: '对战区 C',
        description: '为了备战月底的大赛，来练练手。我们需要一个裁判判罚。',
        organizerType: OrganizerType.PLAYER,
        organizerName: 'ProTester',
        requireReferee: 1,
        allowedDecks: 'Modern 禁牌表'
      }
    ];

    for (const t of tournaments) {
      await this.insert('tournaments', t);
    }

    // D. 插入卡组 [Updated] with deposit
    const decks: relationalStore.ValuesBucket[] = [
      {
        id: 'd001',
        name: '【YGO】救援王牌 Rescue-ACE',
        gameType: GameType.YGO,
        rentalFeePerHour: 5, // 降低租金
        deposit: 200, // 押金
        stock: 2,
        description: '当前环境T1卡组，操作简单，推荐回坑玩家。',
        tags: JSON.stringify(['主流', 'T1', '控制']),
        composition: JSON.stringify({ main: ['救援王牌-湍流 x3', '灰流丽 x3', '增殖的G x3', '罪宝狩猎 x3'] })
      },
      {
        id: 'd002',
        name: '【YGO】珠泪哀歌族 (高罕)',
        gameType: GameType.YGO,
        rentalFeePerHour: 10,
        deposit: 800, // 高罕贵卡组押金高
        stock: 1,
        description: '全钻高罕贵度，小心轻放！体验极致的堆墓快感。',
        tags: JSON.stringify(['高罕', '展开', '说书']),
        composition: JSON.stringify({ main: ['雷诺哈特 x3', '塞壬人鱼 x3', '壹世坏-珍珠世界 x3'] })
      },
      {
        id: 'd003',
        name: '【MTG】纯红快攻 Mono-Red',
        gameType: GameType.MTG,
        rentalFeePerHour: 5,
        deposit: 100,
        stock: 3,
        description: '简单粗暴，推荐新人使用。',
        tags: JSON.stringify(['快攻', '新人推荐']),
        composition: JSON.stringify({ main: ['Monastery Swiftspear x4', 'Lightning Bolt x4', 'Mountain x18'] })
      }
    ];

    for (const d of decks) {
      await this.insert('decks', d);
    }
    
    // [New] Seed Master Database
    const masterCount = await this.queryCount('card_database');
    if (masterCount === 0) {
       console.info('DBHelper: Seeding Master Card Database...');
       const ygoCards = [
         '青眼白龙', '黑魔导', '真红眼黑龙', '死者苏生', '神圣防护罩-反射镜力-',
         '灰流丽', '增殖的G', '无限泡影', '原始生命态 尼比鲁', '墓穴的指名者',
         '抹杀的指名者', '强欲而金满之壶', '金满而谦虚之壶', '强欲之壶', '天霆号 阿宙斯',
         '访问码语者', '鲜花女男爵', '召命之神弓-阿波罗萨', 'I:P伪装舞会莱娜', '连接栗子球',
         '闪刀姬-零', '闪刀姬-火', '闪刀起动-交闪', '闪刀机关-多任务战机', '救援王牌-湍流',
         '纯爱妖精', '历尔波', '诺阿尔', '丰沃之神', '珠泪哀歌族·雷诺哈特'
       ];
       const mtgCards = [
         'Black Lotus', 'Mox Pearl', 'Mox Sapphire', 'Mox Jet', 'Mox Ruby', 'Mox Emerald',
         'Time Walk', 'Ancestral Recall', 'Timetwister', 'Lightning Bolt', 'Counterspell',
         'Birds of Paradise', 'Sol Ring', 'Mana Crypt', 'Force of Will', 'Swords to Plowshares',
         'Sheoldred, the Apocalypse', 'The One Ring', 'Orcish Bowmasters', 'Ragavan, Nimble Pilferer',
         'Urza\'s Saga', 'Teferi, Time Raveler', 'Jace, the Mind Sculptor', 'Liliana of the Veil',
         'Wrenn and Six', 'Oko, Thief of Crowns', 'Uro, Titan of Nature\'s Wrath', 'Primeval Titan'
       ];

       for(let i=0; i<ygoCards.length; i++) {
         await this.insert('card_database', {
           id: `ygo_m_${i}`, name: ygoCards[i], game_type: 'YGO', card_code: `MOCK-Y${i.toString().padStart(3,'0')}`,
           rarity: i < 5 ? 'UR' : (i < 15 ? 'SR' : 'N'), type: 'Card'
         });
       }
       for(let i=0; i<mtgCards.length; i++) {
         await this.insert('card_database', {
           id: `mtg_m_${i}`, name: mtgCards[i], game_type: 'MTG', card_code: `MOCK-M${i.toString().padStart(3,'0')}`,
           rarity: i < 9 ? 'Mythic' : (i < 20 ? 'Rare' : 'Common'), type: 'Card'
         });
       }
       console.info('DBHelper: Master Database seeded.');
    }
  }
  
  // 简单查询返回 ResultSet
  async query(tableName: string): Promise<relationalStore.ResultSet | null> {
    await this.ensureInit();
    if (!this.rdbStore) return null;
    let predicates = new relationalStore.RdbPredicates(tableName);
    return await this.rdbStore.query(predicates);
  }

  // 通用插入
  async insert(tableName: string, data: relationalStore.ValuesBucket): Promise<number> {
    await this.ensureInit();
    if (!this.rdbStore) return -1;
    return await this.rdbStore.insert(tableName, data);
  }

  // 通用更新
  async update(tableName: string, data: relationalStore.ValuesBucket, id: string): Promise<void> {
    await this.ensureInit();
    if (!this.rdbStore) return;
    let predicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('id', id);
    await this.rdbStore.update(data, predicates);
  }
  
  // 删除
  async delete(tableName: string, whereClause: DeleteCriteria): Promise<void> {
    await this.ensureInit();
    if (!this.rdbStore) return;
    let predicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo(whereClause.field, whereClause.value);
    await this.rdbStore.delete(predicates);
  }

  // 内部辅助: 查询行数
  private async queryCount(tableName: string): Promise<number> {
    // 这里的 queryCount 只在 seedData 用，而 seedData 只在 init 用，此时 rdbStore 肯定有了
    if (!this.rdbStore) return 0;
    let predicates = new relationalStore.RdbPredicates(tableName);
    let resultSet = await this.rdbStore.query(predicates);
    let count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  isReady(): boolean {
    return this.rdbStore !== null;
  }
}

export default new DBHelper(); // Singleton instance
