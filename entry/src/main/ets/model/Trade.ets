export enum TradeType {
  WANT = '求购/求换',
  HAVE = '出售/可换'
}

export interface TradeListing {
  id: string;
  userId: string;
  username?: string;
  type: TradeType;
  gameType: string; // YGO, MTG
  cardName: string;
  price: number;
  description: string;
  status: number; // 0=Open, 1=Closed
  createdAt: number;
}
