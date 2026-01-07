export enum MatchStatus {
  PENDING = 'PENDING',
  FINISHED = 'FINISHED'
}

export interface Match {
  id: string;
  tournamentId: string;
  round: number;
  playerAId: string;
  playerBId: string;
  playerAName: string;
  playerBName: string;
  scoreA: number;
  scoreB: number;
  winnerId?: string;
  status: MatchStatus;
  tableNumber: number; // 桌号
}
