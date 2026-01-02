import { GameType } from './Card';

export enum TournamentStatus {
  PENDING_APPROVAL = '待审核',
  REJECTED = '已拒绝',
  REGISTERING = '报名中',
  RUNNING = '进行中',
  FINISHED = '已结束'
}

export enum OrganizerType {
  SHOP = '官方举办',
  PLAYER = '玩家举办'
}

export enum YGOFormat {
  OCG_ADVANCED = 'OCG Advanced (标准)',
  TCG_ADVANCED = 'TCG Advanced (标准)',
  TRADITIONAL = 'Traditional (传统)',
  GOAT = 'Time Wizard (Goat 2005)',
  EDISON = 'Time Wizard (Edison 2010)',
  SPEED_DUEL = 'Speed Duel',
  RUSH_DUEL = 'Rush Duel'
}

export enum MTGFormat {
  STANDARD = 'Standard (标准)',
  PIONEER = 'Pioneer (先驱)',
  MODERN = 'Modern (摩登)',
  LEGACY = 'Legacy (薪传)',
  VINTAGE = 'Vintage (特选)',
  COMMANDER = 'Commander (指挥官/EDH)',
  PAUPER = 'Pauper (预组)',
  DRAFT = 'Draft (轮抽)',
  SEALED = 'Sealed (现开)'
}

export interface MatchPairing {
  tableNo: number;
  playerA: string;
  playerB: string;
  scoreA: number; // 2
  scoreB: number; // 1
  winner?: string;
}

export interface TournamentRound {
  roundNumber: number; // 第几轮
  pairings: MatchPairing[];
}

export interface Tournament {
  id: string;
  title: string; // e.g., "12月店赛 - 瑞士轮"
  gameType: GameType;
  // [新增] 比赛赛制 (存字符串，可以是 YGOFormat 或 MTGFormat 的值)
  format: string;
  
  startTime: string; // YYYY-MM-DD HH:mm
  status: TournamentStatus;
  maxPlayers: number;
  currentPlayers: number;
  entryFee: number; // 报名费
  location: string; // e.g., "A区 - 1号桌"
  description: string;
  
  // [新增] 举办者信息
  organizerType: OrganizerType;
  organizerName: string; // "官方" 或 玩家昵称
  organizerId?: string; // [New] 举办者ID，用于判断是否免单
  
  // [新增] 赛事海报 (ResourceStr or Url)
  poster?: string;

  // [新增] 是否需要裁判 (玩家举办时)
  requireReferee: boolean;
  refereeId?: string;
  
  // [新增] 卡组限制描述 (e.g. "仅限红白黑", "禁卡表2024.1")
  allowedDecks: string;

  // 详细赛程数据
  rounds?: TournamentRound[]; 
  // 当前用户是否已报名
  isJoined?: boolean;
}
