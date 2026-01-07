import DBHelper from '../common/DBHelper';
import { Match, MatchStatus } from '../model/Match';
import relationalStore from '@ohos.data.relationalStore';
import { User } from '../model/User';

// [Fix] Define explicit interface
interface PlayerInfo {
  id: string;
  name: string;
}

export class MatchService {

  // 生成第一轮对阵 (基于真实报名数据)
  static async generatePairings(tournamentId: string): Promise<void> {
    // 1. 检查是否已经有对阵了 (幂等性)
    const existing = await DBHelper.query('matches');
    let hasMatch = false;
    if (existing) {
      while(existing.goToNextRow()) {
          if(existing.getString(existing.getColumnIndex('tournamentId')) === tournamentId) {
              hasMatch = true;
              break;
          }
      }
      existing.close();
    }
    if (hasMatch) return; 

    // 2. [Real Data] 获取真实报名玩家 ID
    const enrolledUserIds: string[] = [];
    const enrollRs = await DBHelper.query('enrollments');
    if (enrollRs) {
      while(enrollRs.goToNextRow()) {
        if(enrollRs.getString(enrollRs.getColumnIndex('tournament_id')) === tournamentId) {
          enrolledUserIds.push(enrollRs.getString(enrollRs.getColumnIndex('user_id')));
        }
      }
      enrollRs.close();
    }

    if (enrolledUserIds.length < 2) return; // 人数不足，无法开赛

    // 3. [Real Data] 获取玩家详情 (Username)
    const players: PlayerInfo[] = []; // [Fix] Use interface
    const userRs = await DBHelper.query('users');
    if (userRs) {
      while(userRs.goToNextRow()) {
        const uId = userRs.getString(userRs.getColumnIndex('id'));
        if (enrolledUserIds.includes(uId)) {
           const pInfo: PlayerInfo = {
             id: uId,
             name: userRs.getString(userRs.getColumnIndex('username'))
           };
           players.push(pInfo);
        }
      }
      userRs.close();
    }

    // 4. 随机洗牌 (Shuffle) - [Fix] No destructuring
    for (let i = players.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        const temp = players[i];
        players[i] = players[j];
        players[j] = temp;
    }

    // 5. 生成 Match 记录
    let tableNo = 1;
    for (let i = 0; i < players.length; i += 2) {
      // 处理轮空 (Bye)
      if (i + 1 >= players.length) {
        // 最后一人轮空，视为自动获胜
        const pA = players[i];
        const matchId = `m_${tournamentId}_r1_t${tableNo}`;
        const values: relationalStore.ValuesBucket = {
            id: matchId,
            tournamentId: tournamentId,
            round: 1,
            playerAId: pA.id,
            playerBId: 'BYE',
            playerAName: pA.name,
            playerBName: '--- 轮空 ---',
            scoreA: 2, scoreB: 0,
            status: MatchStatus.FINISHED,
            winnerId: 'playerA',
            tableNumber: tableNo
        };
        await DBHelper.insert('matches', values);
        break;
      }

      const pA = players[i];
      const pB = players[i+1];
      const matchId = `m_${tournamentId}_r1_t${tableNo}`;

      const values: relationalStore.ValuesBucket = {
        id: matchId,
        tournamentId: tournamentId,
        round: 1,
        playerAId: pA.id,
        playerBId: pB.id,
        playerAName: pA.name,
        playerBName: pB.name,
        scoreA: 0, scoreB: 0,
        status: MatchStatus.PENDING,
        tableNumber: tableNo
      };
      await DBHelper.insert('matches', values);
      tableNo++;
    }
  }

  static async getMatches(tournamentId: string): Promise<Match[]> {
    await MatchService.generatePairings(tournamentId);

    const matches: Match[] = [];
    const rs = await DBHelper.query('matches');
    if (!rs) return [];
    
    while (rs.goToNextRow()) {
      if (rs.getString(rs.getColumnIndex('tournamentId')) === tournamentId) {
        matches.push({
          id: rs.getString(rs.getColumnIndex('id')),
          tournamentId: rs.getString(rs.getColumnIndex('tournamentId')),
          round: rs.getLong(rs.getColumnIndex('round')),
          playerAId: rs.getString(rs.getColumnIndex('playerAId')),
          playerBId: rs.getString(rs.getColumnIndex('playerBId')),
          playerAName: rs.getString(rs.getColumnIndex('playerAName')),
          playerBName: rs.getString(rs.getColumnIndex('playerBName')),
          scoreA: rs.getLong(rs.getColumnIndex('scoreA')),
          scoreB: rs.getLong(rs.getColumnIndex('scoreB')),
          winnerId: rs.getString(rs.getColumnIndex('winnerId')),
          status: rs.getString(rs.getColumnIndex('status')) as MatchStatus,
          tableNumber: rs.getLong(rs.getColumnIndex('tableNumber'))
        });
      }
    }
    rs.close();
    return matches.sort((a, b) => a.tableNumber - b.tableNumber);
  }

  static async submitResult(matchId: string, scoreA: number, scoreB: number): Promise<boolean> {
    const winnerId = scoreA > scoreB ? 'playerA' : (scoreB > scoreA ? 'playerB' : 'DRAW');
    
    const values: relationalStore.ValuesBucket = {
      scoreA: scoreA,
      scoreB: scoreB,
      status: MatchStatus.FINISHED,
      winnerId: winnerId
    };
    
    await DBHelper.update('matches', values, matchId);
    return true;
  }
}
