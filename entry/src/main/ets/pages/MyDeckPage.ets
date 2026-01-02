import router from '@ohos.router';
import { InventoryService } from '../service/InventoryService';
import { Deck, DeckCards } from '../model/PlayerDeck';
import promptAction from '@ohos.promptAction';
import { PublishDeckDialog } from '../view/dialog/PublishDeckDialog'; // [New]
import { DeckEditorDialog } from '../view/dialog/DeckEditorDialog'; // [New]

// [新增] 定义接口替代对象字面量
interface CardCount {
  name: string;
  count: number;
}

// [新增] 聚合卡片辅助函数
function aggregateCards(cards: string[]): CardCount[] {
  const map = new Map<string, number>();
  cards.forEach(c => {
    map.set(c, (map.get(c) || 0) + 1);
  });
  const result: CardCount[] = [];
  map.forEach((count, name) => {
    result.push({ name, count });
  });
  return result;
}

@Entry
@Component
struct MyDeckPage {
  @State myDecks: Deck[] = [];
  
  editorController: CustomDialogController | null = null;
  publishController: CustomDialogController | null = null; // [New]

  async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.myDecks = await InventoryService.getPlayerDecks();
  }
  
  openPublish(deck: Deck) {
    this.publishController = new CustomDialogController({
      builder: PublishDeckDialog({
        deck: deck,
        controller: undefined
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.publishController.open();
  }

  openEditor(deck: Deck | null) {
    this.editorController = new CustomDialogController({
      builder: DeckEditorDialog({
        deck: deck,
        controller: undefined,
        confirmAction: async (d) => {
          console.info('[MyDeckPage] confirmAction called');
          let success = false;
          if (deck) {
            success = await InventoryService.updatePlayerDeck(d);
          } else {
            success = await InventoryService.createPlayerDeck(d);
            console.info('[MyDeckPage] createPlayerDeck result:', success);
          }
          
          if (success) {
            promptAction.showToast({ message: '保存成功' });
            await this.loadData();
          } else {
            promptAction.showToast({ message: '保存失败，请重试或重置数据库' });
          }
          console.info('[MyDeckPage] loadData finished, count:', this.myDecks.length);
        }
      }),
      autoCancel: true
    });
    this.editorController.open();
  }

  async handleDelete(id: string) {
    AlertDialog.show({
      title: '删除确认',
      message: '确定要删除这个卡组吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除', fontColor: 'red',
        action: async () => {
          await InventoryService.deletePlayerDeck(id);
          this.loadData();
        }
      }
    });
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.mtga_icon')).width(24).height(24).onClick(() => router.back())
        Text('我的卡本 / 构筑').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })
        Blank()
        Button('+ 新建').height(30).fontSize(12).onClick(() => this.openEditor(null))
      }
      .width('100%').padding(15).backgroundColor('#FFF')

      if (this.myDecks.length === 0) {
        Column() {
          Text('暂无自建卡组').fontSize(16).fontColor('#999').margin({ top: 50, bottom: 10 })
          Text('创建你的第一套卡组，征战赛场！').fontSize(12).fontColor('#CCC').margin({ bottom: 20 })
          Button('+ 新建卡组')
            .onClick(() => this.openEditor(null))
            .backgroundColor('#007DFF')
        }.width('100%').alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.myDecks, (item: Deck) => {
            ListItem() {
              this.DeckItem(item)
            }
          }, (item: Deck) => item.id)
        }
        .layoutWeight(1).width('100%').padding(15)
      }
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }

  @Builder DeckItem(deck: Deck) {
    Column() {
      Row() {
        Text(deck.gameType).fontSize(10).fontColor('#FFF')
          .backgroundColor(deck.gameType === 'YGO' ? '#D94841' : '#007DFF')
          .padding({ left: 4, right: 4 }).borderRadius(2)
          .margin({ right: 8 })
        
        Text(deck.name).fontWeight(FontWeight.Bold).fontSize(16)
        Blank()
        Button('发布').height(24).fontSize(10).backgroundColor('#28C76F').margin({ right: 8 })
          .onClick(() => this.openPublish(deck))
        Text('✏️').onClick(() => this.openEditor(deck)).margin({ right: 15 })
        Text('🗑️').onClick(() => this.handleDelete(deck.id))
      }.width('100%')

      Text(`${deck.format} | 主卡组: ${deck.cards.main.length} 张`)
        .fontSize(12).fontColor('#666').margin({ top: 5 })
      
      // 预览前几张卡
      Row() {
        ForEach(aggregateCards(deck.cards.main).slice(0, 3), (item: CardCount) => {
          Text(`${item.name} *${item.count}`).fontSize(10).backgroundColor('#EEE').padding(4).borderRadius(4).margin({ right: 5 })
        })
        if (new Set(deck.cards.main).size > 3) Text('...').fontSize(10).fontColor('#999')
      }.margin({ top: 8 })
    }
    .width('100%').padding(15).backgroundColor('#FFF').borderRadius(10)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
  }
}
