import router from '@ohos.router';
import { AuthService } from '../service/AuthService';

@Entry
@Component
struct WalletPage {
  @State balance: number = 0.0;

  async aboutToAppear() {
    this.loadBalance();
  }

  async loadBalance() {
    this.balance = await AuthService.getUserBalance();
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.mtga_icon')).width(24).height(24).onClick(() => router.back())
        Text('我的钱包').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })
      }
      .width('100%').padding(15).backgroundColor('#FFF')

      Column() {
        Text('当前积分 (1元 = 1积分)').fontSize(14).fontColor('#DDD')
        Text(this.balance.toFixed(0)).fontSize(40).fontColor('#FFF').fontWeight(FontWeight.Bold).margin({ top: 10 })
        Text('可用于赛事报名与卡组租借').fontSize(10).fontColor('#EEE').margin({ top: 5 })
      }
      .width('90%').height(150).backgroundColor('#28C76F').borderRadius(16).justifyContent(FlexAlign.Center).margin({ top: 20 })

      Text('充值 (充值金额将自动转换为等额积分)').fontSize(16).fontWeight(FontWeight.Bold).width('90%').margin({ top: 20, bottom: 10 })

      Grid() {
        GridItem() { this.ChargeBtn(6) }
        GridItem() { this.ChargeBtn(30) }
        GridItem() { this.ChargeBtn(68) }
        GridItem() { this.ChargeBtn(128) }
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(10).columnsGap(10)
      .width('90%').height(200)
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }

  @Builder ChargeBtn(amount: number) {
    Button(`￥${amount} → ${amount} 积分`)
      .width('100%').height(60).backgroundColor('#FFF').fontColor('#333')
      .onClick(async () => {
        await AuthService.rechargeWallet(amount);
        await this.loadBalance();
        AlertDialog.show({ message: `充值成功！获得 ${amount} 积分` });
      })
  }
}
