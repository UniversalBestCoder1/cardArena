import { MockService } from '../mock/MockService';
import { RentableDeck } from '../model/RentableDeck';
import { SingleCard } from '../model/Inventory';
import { Deck } from '../model/PlayerDeck';
import { Card, GameType } from '../model/Card';

export class InventoryService {
  
  static async getRentableDecks(): Promise<RentableDeck[]> {
    return MockService.getRentableDecks();
  }

  static async rentDeck(deckId: string): Promise<boolean> {
    return MockService.rentDeck(deckId);
  }

  static async returnDeck(deckId: string): Promise<boolean> {
    return MockService.returnDeck(deckId);
  }

  static async getSingles(): Promise<SingleCard[]> {
    return MockService.getSingles();
  }

  // --- 搜索卡牌 ---
  static async searchCards(keyword: string, gameType: GameType = GameType.YGO): Promise<Card[]> {
    return MockService.searchCards(keyword, gameType);
  }

  // --- 玩家自建卡组 ---
  static async getPlayerDecks(): Promise<Deck[]> {
    return MockService.getPlayerDecks();
  }

  static async createPlayerDeck(deck: Deck): Promise<boolean> {
    return MockService.createPlayerDeck(deck);
  }

  static async updatePlayerDeck(deck: Deck): Promise<boolean> {
    return MockService.updatePlayerDeck(deck);
  }

  static async deletePlayerDeck(deckId: string): Promise<boolean> {
    return MockService.deletePlayerDeck(deckId);
  }
}