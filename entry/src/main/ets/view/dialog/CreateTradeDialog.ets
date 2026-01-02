import { MockService } from '../../mock/MockService';
import { TradeListing, TradeType } from '../../model/Trade';
import promptAction from '@ohos.promptAction';

@CustomDialog
export struct CreateTradeDialog {
  controller: CustomDialogController;
  onConfirm: () => void = () => {};
  
  @State tradeType: TradeType = TradeType.WANT;
  @State gameType: string = 'YGO';
  @State cardName: string = '';
  @State price: number = 0;
  @State description: string = '';

  async handleSubmit() {
    if (!this.cardName) {
      promptAction.showToast({message: '请输入卡片名称'});
      return;
    }
    const t: TradeListing = {
      id: `trade_${new Date().getTime()}`,
      userId: '', // MockService fills this
      type: this.tradeType,
      gameType: this.gameType,
      cardName: this.cardName,
      price: this.price,
      description: this.description,
      status: 0,
      createdAt: new Date().getTime()
    };
    
    await MockService.createTradeListing(t);
    promptAction.showToast({message: '发布成功'});
    this.onConfirm();
    this.controller.close();
  }

  build() {
    Column({ space: 12 }) {
      Text('发布交易信息').fontSize(18).fontWeight(FontWeight.Bold)
      
      Row() {
        Button('求购 / 求换')
          .backgroundColor(this.tradeType === TradeType.WANT ? '#FF9F43' : '#EEE')
          .fontColor(this.tradeType === TradeType.WANT ? '#FFF' : '#333')
          .onClick(() => this.tradeType = TradeType.WANT)
          .layoutWeight(1).margin({right: 5})
        Button('出售 / 可换')
          .backgroundColor(this.tradeType === TradeType.HAVE ? '#28C76F' : '#EEE')
          .fontColor(this.tradeType === TradeType.HAVE ? '#FFF' : '#333')
          .onClick(() => this.tradeType = TradeType.HAVE)
          .layoutWeight(1)
      }.width('100%')

      Row() {
        Text('游戏: ').width(50)
        Radio({ value: 'YGO', group: 'gt' }).checked(this.gameType === 'YGO').onChange((v) => { if(v) this.gameType='YGO'})
        Text('YGO').margin({right: 15})
        Radio({ value: 'MTG', group: 'gt' }).checked(this.gameType === 'MTG').onChange((v) => { if(v) this.gameType='MTG'})
        Text('MTG')
      }.width('100%')

      TextInput({ placeholder: '卡片名称 (e.g. 灰流丽)', text: this.cardName })
        .onChange((v) => this.cardName = v)
      
      TextInput({ placeholder: '期望价格 (或估价)', text: this.price ? this.price.toString() : '' })
        .type(InputType.Number)
        .onChange((v) => this.price = parseInt(v) || 0)

      TextArea({ placeholder: '备注 (成色、版本、只想换什么...)' })
        .height(80)
        .onChange((v) => this.description = v)

      Row() {
        Button('取消').backgroundColor('#CCC').width('40%').onClick(() => this.controller.close())
        Blank()
        Button('发布').width('40%').onClick(() => this.handleSubmit())
      }.width('100%').margin({top: 10})
    }
    .padding(20).backgroundColor('#FFF').borderRadius(12).width('90%')
  }
}