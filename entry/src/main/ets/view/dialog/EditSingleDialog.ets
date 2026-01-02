import { SingleCard } from '../../model/Inventory';

@CustomDialog
export struct EditSingleDialog {
  @State cardName: string = '';
  @State cardPrice: number = 0;
  @State cardStock: number = 0;
  @State isProxy: boolean = false;

  targetCard: SingleCard | null = null;
  confirmAction: (name: string, price: number, stock: number, isProxy: boolean) => void = () => {};
  controller: CustomDialogController;

  aboutToAppear() {
    if (this.targetCard) {
      this.cardName = this.targetCard.name;
      this.cardPrice = this.targetCard.price;
      this.cardStock = this.targetCard.stock;
      this.isProxy = this.targetCard.is_proxy;
    }
  }

  build() {
    Column({ space: 15 }) {
      Text('编辑单卡库存').fontSize(18).fontWeight(FontWeight.Bold)
      
      TextInput({ placeholder: '卡牌名称', text: this.cardName })
        .onChange((val) => this.cardName = val)

      Row() {
        Text('价格(￥): ').width(80)
        TextInput({ placeholder: '0', text: this.cardPrice.toString() })
          .type(InputType.Number)
          .layoutWeight(1)
          .onChange((val) => this.cardPrice = parseInt(val) || 0)
      }

      Row() {
        Text('库存量: ').width(80)
        TextInput({ placeholder: '0', text: this.cardStock.toString() })
          .type(InputType.Number)
          .layoutWeight(1)
          .onChange((val) => this.cardStock = parseInt(val) || 0)
      }

      Row() {
        Checkbox({ name: 'isProxy' })
          .select(this.isProxy)
          .onChange((val) => this.isProxy = val)
        Text('标记为代牌 (Proxy)').fontSize(14).fontColor('#666')
      }.width('100%')

      Row() {
        Button('取消').onClick(() => this.controller.close()).backgroundColor('#CCC').width('40%')
        Blank()
        Button('保存')
          .onClick(() => {
            this.confirmAction(this.cardName, this.cardPrice, this.cardStock, this.isProxy);
            this.controller.close();
          })
          .width('40%')
      }.width('100%').margin({ top: 10 })
    }
    .padding(20).backgroundColor('#FFF').borderRadius(12).width('90%')
  }
}