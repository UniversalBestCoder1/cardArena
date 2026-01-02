import { MockService } from '../mock/MockService';
import { Tournament } from '../model/Tournament';
import { User } from '../model/User';

export class TournamentService {
  
  static async getTournaments(): Promise<Tournament[]> {
    return MockService.getTournaments();
  }

  static async createTournament(t: Tournament): Promise<boolean> {
    return MockService.createTournament(t);
  }

  static async deleteTournament(id: string): Promise<boolean> {
    return MockService.deleteTournament(id);
  }

  static async joinTournament(tournamentId: string): Promise<boolean> {
    return MockService.joinTournament(tournamentId);
  }

  static async cancelTournament(tournamentId: string): Promise<boolean> {
    return MockService.cancelTournament(tournamentId);
  }

  // [New] Approval Flow
  static async approveTournament(id: string): Promise<boolean> {
    return MockService.approveTournament(id);
  }

  static async rejectTournament(id: string): Promise<boolean> {
    return MockService.rejectTournament(id);
  }

  // [New] Player Management
  static async getTournamentPlayers(tournamentId: string): Promise<User[]> {
    return MockService.getTournamentPlayers(tournamentId);
  }

  static async kickPlayer(tournamentId: string, userId: string): Promise<boolean> {
    return MockService.kickPlayer(tournamentId, userId);
  }
}