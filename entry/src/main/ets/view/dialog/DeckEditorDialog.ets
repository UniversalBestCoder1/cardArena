import { Deck, DeckCards } from '../../model/PlayerDeck';
import { CardSelector } from '../CardSelector';
import promptAction from '@ohos.promptAction';

interface CardCount {
  name: string;
  count: number;
}

// 聚合卡片辅助函数
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

@CustomDialog
export struct DeckEditorDialog {
  @State deckName: string = '';
  @State gameType: string = 'YGO';
  @State format: string = 'OCG Advanced';
  @State mainCards: string[] = [];
  
  deck: Deck | null = null;
  confirmAction: (d: Deck) => void = () => {};
  controller: CustomDialogController;

  aboutToAppear() {
    if (this.deck) {
      this.deckName = this.deck.name;
      this.gameType = this.deck.gameType;
      this.format = this.deck.format || '';
      this.mainCards = [...this.deck.cards.main];
    }
  }

  removeCardByName(name: string) {
    const index = this.mainCards.indexOf(name);
    if (index !== -1) {
      this.mainCards.splice(index, 1);
    }
  }

  build() {
    Column({ space: 15 }) {
      Text(this.deck ? '编辑卡组' : '新建卡组').fontSize(18).fontWeight(FontWeight.Bold)
      
      // 可滚动的内容区域
      Scroll() {
        Column({ space: 15 }) {
          TextInput({ placeholder: '卡组名称', text: this.deckName })
            .onChange((val) => this.deckName = val)
          
          Row() {
            Text('游戏类型: ').width(70)
            Select([{ value: 'YGO' }, { value: 'MTG' }])
              .value(this.gameType)
              .onSelect((index, value) => this.gameType = value)
          }.width('100%').justifyContent(FlexAlign.Start)

          TextInput({ placeholder: '赛制 (e.g. OCG/Standard)', text: this.format })
            .onChange((val) => this.format = val)

          // 构筑编辑区
          Column() {
            Text(`主卡组 (${this.mainCards.length})`).fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 5 })
            
            // 已选卡片列表 (聚合显示)
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(aggregateCards(this.mainCards), (item: CardCount) => {
                Row() {
                  Text(item.name).fontSize(12)
                  Text(` *${item.count}`).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#007DFF')
                  Text(' - ').fontSize(14).fontColor('#D94841').fontWeight(FontWeight.Bold)
                    .margin({ left: 4 })
                    .onClick(() => this.removeCardByName(item.name))
                }
                .padding(6)
                .backgroundColor('#F0F0F0')
                .borderRadius(4)
                .margin(4)
              }, (item: CardCount) => item.name + item.count)
            }
            // 移除最大高度限制，让 ScrollView 管理
            // .constraintSize({ minHeight: 60, maxHeight: 150 }) 

            Divider().color('#EEE').margin({ top: 10, bottom: 10 })

            // 卡牌搜索选择器
            Text('添加卡牌').fontSize(12).fontColor('#999').width('100%').margin({ bottom: 5 })
            CardSelector({
              gameType: this.gameType, 
              onSelect: (cardName: string) => {
                this.mainCards.push(cardName);
                promptAction.showToast({ message: `已添加: ${cardName}` });
              }
            })
            .constraintSize({ minHeight: 250, maxHeight: 400 }) 

          }
          .padding(10).border({ width: 1, color: '#EEE', radius: 8 }).width('100%')
        }
      }
      .layoutWeight(1) // 关键：占据剩余空间
      .width('100%')

      // 底部按钮 (固定在底部)
      Row() {
        Button('取消').backgroundColor('#CCC').width('40%').onClick(() => this.controller.close())
        Blank()
        Button('保存').width('40%').onClick(() => {
          if (!this.deckName) {
            promptAction.showToast({ message: '请输入名称' });
            return;
          }
          const newDeck: Deck = {
            id: this.deck ? this.deck.id : `pd_${new Date().getTime()}`,
            name: this.deckName,
            gameType: this.gameType,
            format: this.format,
            cards: { main: this.mainCards, extra: [], side: [] },
            createdAt: this.deck ? this.deck.createdAt : new Date().getTime()
          };
          this.confirmAction(newDeck);
          this.controller.close();
        })
      }.width('100%')
    }
    .padding(20).backgroundColor('#FFF').borderRadius(12).width('95%')
    .height('80%') // [Fixed] 限制弹窗总高度，防止撑爆屏幕
  }
}