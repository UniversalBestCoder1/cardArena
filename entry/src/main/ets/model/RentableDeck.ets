import { GameType } from './Card';

// [Fixed] 提取独立的接口
export interface DeckComposition {
  main: string[];
  extra?: string[];
  side?: string[];
}

export interface RentableDeck {
  id: string;
  name: string; // e.g., "珠泪哀歌族 (全钻)"
  gameType: GameType;
  coverImage: string; // 封面图
  rentalFeePerHour: number; // 租金 (元/小时)
  stock: number; // 库存数量
  deposit: number; // [新增] 押金 (积分)
  description: string; // 构筑简介
  tags: string[]; // e.g., ["主流", "高难度", "展开"]
  isRentedByMe?: boolean; // 当前用户是否正在租用
  composition?: DeckComposition; // [Fixed] 使用接口类型
}
