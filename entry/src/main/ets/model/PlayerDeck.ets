export interface Deck {
  id: string;
  name: string;
  gameType: string;
  format?: string; // 赛制
  cards: DeckCards; // 构筑详情
  coverImage?: string;
  createdAt: number;
}

export interface DeckCards {
  main: string[]; // 主卡组卡片名称列表
  extra: string[]; // 额外
  side: string[]; // 副卡组
}
