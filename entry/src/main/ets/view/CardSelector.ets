import { Card, GameType } from '../model/Card';
import { InventoryService } from '../service/InventoryService';

@Component
export struct CardSelector {
  @Prop gameType: string = 'YGO'; // 接收父组件传入的游戏类型
  @State searchText: string = '';
  @State searchResults: Card[] = [];
  onSelect: (cardName: string) => void = () => {};

  async handleSearch() {
    if (!this.searchText.trim()) return;
    
    // 转换 string 到 GameType 枚举
    const typeEnum = this.gameType === 'MTG' ? GameType.MTG : GameType.YGO;
    this.searchResults = await InventoryService.searchCards(this.searchText, typeEnum);
  }

  build() {
    Column() {
// ... (rest of build method)
      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索卡牌...', text: this.searchText })
          .layoutWeight(1)
          .height(36)
          .onChange((val) => this.searchText = val)
          .onSubmit(() => this.handleSearch())
        
        Button('搜索')
          .height(36)
          .margin({ left: 8 })
          .onClick(() => this.handleSearch())
      }.width('100%').padding(10)

      // 结果列表
      List({ space: 8 }) {
        ForEach(this.searchResults, (card: Card) => {
          ListItem() {
            Row() {
              Image(card.imageUrl)
                .width(40).height(58).objectFit(ImageFit.Contain)
                .backgroundColor('#EEE')
              
              Column() {
                Text(card.name).fontSize(14).fontWeight(FontWeight.Bold)
                Text(`${card.type} | ${card.rarity}`).fontSize(10).fontColor('#666')
                Text(`参考价: ￥${card.priceAvg}`).fontSize(10).fontColor('#FF9500')
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
              .layoutWeight(1)

              Button('添加')
                .height(24).fontSize(10)
                .onClick(() => {
                  this.onSelect(card.name);
                })
            }
            .width('100%')
            .padding(8)
            .backgroundColor('#F9F9F9')
            .borderRadius(8)
          }
        }, (card: Card) => card.id)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .height(300) // 限制高度，作为组件使用
    .backgroundColor('#FFF')
  }
}