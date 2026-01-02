import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { InventoryService } from '../../../main/ets/service/InventoryService';
import { MockService } from '../../../main/ets/mock/MockService';
import DBHelper from '../../../main/ets/common/DBHelper';
import { Deck } from '../../../main/ets/model/PlayerDeck';
import { User } from '../../../main/ets/model/User';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

export default function deckIntegrationTest() {
  describe('DeckIntegrationTest', () => {
    
    // 1. 环境准备
    beforeAll(async () => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      let context: common.Context;
      try {
        const ability = await delegator.getCurrentTopAbility();
        context = ability.context;
        console.info('[Test] Using UIAbilityContext');
      } catch (e) {
        context = await delegator.getAppContext();
        console.info('[Test] Using AppContext');
      }
      
      const TEST_DB = 'CardArena_Test_v1.db';
      
      console.info('[Test] Initializing DB:', TEST_DB);
      try {
        await relationalStore.deleteRdbStore(context, TEST_DB);
      } catch (e) {
        console.info('Delete store failed (maybe not exist):', JSON.stringify(e));
      }

      try {
        await DBHelper.init(context, TEST_DB);
      } catch (err) {
        console.error('[Test] DBHelper Init threw:', JSON.stringify(err));
        // Fail immediately if DB cannot open
        expect(false).assertTrue(); 
      }
      
      // Verify DB is working
      const testInsert = await DBHelper.insert('users', { id: 'test_db_check', username: 'check' });
      console.info('[Test] DB Check Insert result:', testInsert);
      if (testInsert < 0) {
        throw new Error('DB Init Failed: insert returned -1');
      }
    });

    // [Fixed] 每个测试前都确保用户登录状态
    beforeEach(() => {
      const mockUser: User = {
        id: 'u_test_tester',
        username: 'TestUser',
        role: 'PLAYER',
        wallet_balance: 1000
      };
      AppStorage.SetOrCreate('currentUser', mockUser);
      
      const user = AppStorage.Get<User>('currentUser');
      console.info('[Test] Current User set:', JSON.stringify(user));
    });

    // 2. 测试用例：创建卡组
    it('CreateDeck_ShouldSuccess', 0, async () => {
      const newDeck: Deck = {
        id: 'deck_test_001',
        name: 'Test Deck',
        gameType: 'YGO',
        format: 'OCG',
        cards: { main: ['Card A', 'Card B'], extra: [], side: [] },
        createdAt: new Date().getTime()
      };

      const result = await InventoryService.createPlayerDeck(newDeck);
      expect(result).assertTrue();
    });

    // 3. 测试用例：查询卡组
    it('GetDecks_ShouldReturnCreatedDeck', 0, async () => {
      const decks = await InventoryService.getPlayerDecks();
      console.info('Test GetDecks count:', decks.length);
      expect(decks.length).assertLarger(0);
      
      const target = decks.find(d => d.id === 'deck_test_001');
      expect(target !== undefined).assertTrue();
      expect(target?.name).assertEqual('Test Deck');
      expect(target?.cards?.main?.length).assertEqual(2);
    });

    // 4. 测试用例：更新卡组
    it('UpdateDeck_ShouldChangeName', 0, async () => {
      const decks = await InventoryService.getPlayerDecks();
      const target = decks.find(d => d.id === 'deck_test_001');
      
      if (target) {
        target.name = 'Updated Name';
        const updateRes = await InventoryService.updatePlayerDeck(target);
        expect(updateRes).assertTrue();

        const updatedDecks = await InventoryService.getPlayerDecks();
        const updatedTarget = updatedDecks.find(d => d.id === 'deck_test_001');
        expect(updatedTarget?.name).assertEqual('Updated Name');
      } else {
        expect().assertFail(); // Fail if setup failed
      }
    });

    // 5. 测试用例：删除卡组
    it('DeleteDeck_ShouldRemoveIt', 0, async () => {
      const delRes = await InventoryService.deletePlayerDeck('deck_test_001');
      expect(delRes).assertTrue();

      const decks = await InventoryService.getPlayerDecks();
      const target = decks.find(d => d.id === 'deck_test_001');
      expect(target === undefined).assertTrue();
    });
  });
}