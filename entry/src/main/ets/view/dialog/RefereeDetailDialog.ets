import { User } from '../../model/User';

@CustomDialog
export struct RefereeDetailDialog {
  referee: User = {} as User;
  controller: CustomDialogController;
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text(this.referee.username || '裁判').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
      
      Row() {
        Text('从业经验: ').fontSize(14).fontColor('#666')
        Text(`${this.referee.refereeProfile?.yearsOfExperience || 0} 年`).fontSize(14).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ bottom: 10 })
      
      Divider().margin({bottom: 10})
      
      Text('擅长游戏:').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({bottom: 5})
      Flex({wrap: FlexWrap.Wrap}) {
        ForEach(this.referee.refereeProfile?.specializedGame || [], (g: string) => {
           Text(g)
            .fontSize(12)
            .backgroundColor('#F1F3F5')
            .padding({left: 8, right: 8, top: 4, bottom: 4})
            .borderRadius(4)
            .margin({right: 5, bottom: 5})
        })
      }.margin({bottom: 10})
      
      Text('擅长赛制:').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({bottom: 5})
      Flex({wrap: FlexWrap.Wrap}) {
        ForEach(this.referee.refereeProfile?.specializedFormats || [], (f: string) => {
           Text(f)
             .fontSize(12)
             .backgroundColor('#F1F3F5')
             .padding({left: 8, right: 8, top: 4, bottom: 4})
             .borderRadius(4)
             .margin({right: 5, bottom: 5})
        })
      }.margin({bottom: 10})

      Text('简介:').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({bottom: 5})
      Text(this.referee.refereeProfile?.bio || '暂无简介')
        .fontSize(14)
        .fontColor('#333')
        .width('100%')
        .margin({bottom: 20})

      Row() {
        Button('取消')
          .backgroundColor('#CCC')
          .onClick(() => this.controller.close())
          .width('40%')
          .margin({right: 10})
          
        Button('选择此裁判')
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
          .width('40%')
      }.justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .width('90%')
    .backgroundColor('#FFF')
    .borderRadius(16)
  }
}