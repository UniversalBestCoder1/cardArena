import router from '@ohos.router';

@Entry
@Component
struct MemberCardPage {
  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.mtga_icon')).width(24).height(24).onClick(() => router.back())
        Text('会员中心').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })
      }
      .width('100%').padding(15).backgroundColor('#FFF')

      // 会员卡
      Stack() {
        Rect()
          .width('90%')
          .height(200)
          .radius(16)
          .linearGradient({
            angle: 135,
            colors: [[0x2c3e50, 0.0], [0x4ca1af, 1.0]] // 深蓝到青色渐变
          })
        
        Column() {
          Text('CardArena VIP').fontSize(24).fontColor('#FFF').fontWeight(FontWeight.Bold)
          Text('No. 8888-8888').fontSize(16).fontColor('#EEE').margin({ top: 10 })
          Blank()
          Text('决斗者_K').fontSize(20).fontColor('#FFF')
        }
        .width('80%').height(160).alignItems(HorizontalAlign.Start)
      }
      .margin({ top: 20 })

      // 权益
      List() {
        ListItem() { this.BenefitItem('购卡 95 折') }
        ListItem() { this.BenefitItem('租借免押金') }
        ListItem() { this.BenefitItem('生日礼包') }
      }
      .margin({ top: 20 }).width('90%').backgroundColor('#FFF').borderRadius(12)
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }

  @Builder BenefitItem(text: string) {
    Row() {
      Text('💎').margin({ right: 10 })
      Text(text).fontSize(16)
    }
    .width('100%').padding(15).border({ width: { bottom: 1 }, color: '#EEE' })
  }
}
