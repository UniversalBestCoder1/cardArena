export enum GameType {
  YGO = '游戏王 (Yu-Gi-Oh!)',
  MTG = '万智牌 (Magic: The Gathering)'
}

export interface Card {
  id: string;
  name: string;
  type: string; // e.g., "Monster/Effect", "Creature"
  rarity: string; // e.g., "SSR", "Mythic Rare"
  imageUrl: string;
  priceMin: number; // 最低价 (CNY)
  priceAvg: number; // 平均价 (CNY)
  description: string; // 效果文本
  gameType: GameType;
  detailUrl?: string; // [新增] 权威网站详情页链接
  // 扩展字段
  atk?: number; // 攻击力
  def?: number; // 防御力
  race?: string; // 种族
  attribute?: string; // 属性 (光/暗...)
}
