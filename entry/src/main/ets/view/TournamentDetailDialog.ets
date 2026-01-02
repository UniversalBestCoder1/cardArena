import { Tournament, TournamentStatus, OrganizerType } from '../model/Tournament';
import { SmartIcon } from '../common/SmartIcon';

@CustomDialog
export struct TournamentDetailDialog {
  t: Tournament = {} as Tournament;
  onJoin: () => void = () => {};
  onCancel: () => void = () => {};
  controller: CustomDialogController;
  currentUserId: string = ''; // Pass explicitly if needed, or use AppStorage inside

  build() {
    Column() {
      // Poster
      if (this.t.poster) {
        if (this.t.poster === 'app.media.ygo_poster') {
           Image($r('app.media.ygo_poster'))
            .width('100%')
            .height(150)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ bottom: 15 })
        } else if (this.t.poster === 'app.media.mtg_poster') {
           Image($r('app.media.mtg_poster'))
            .width('100%')
            .height(150)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ bottom: 15 })
        } else {
           Image(this.t.poster)
            .width('100%')
            .height(150)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .margin({ bottom: 15 })
        }
      }

      // Header
      Row() {
        Text(this.t.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        Text(this.t.status)
          .fontSize(12)
          .fontColor('#FFF')
          .backgroundColor(this.getStatusColor(this.t.status))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
      }
      .width('100%')
      .margin({ bottom: 15 })

      // Info Grid
      GridRow({ columns: 2, gutter: 15 }) {
        GridCol() { this.InfoItem('主办方', this.t.organizerName) }
        GridCol() { this.InfoItem('游戏', this.t.gameType) }
        GridCol() { this.InfoItem('赛制', this.t.format) }
        GridCol() { this.InfoItem('时间', this.t.startTime) }
        GridCol() { this.InfoItem('地点', this.t.location) }
        GridCol() { this.InfoItem('费用', this.t.entryFee === 0 ? '免费' : `${this.t.entryFee} 积分`) }
        
        GridCol({ span: 2 }) { 
           this.InfoItem('卡组限制', this.t.allowedDecks || '无限制') 
        }
        
        if (this.t.organizerType === OrganizerType.PLAYER && this.t.requireReferee) {
          GridCol({ span: 2 }) {
             Row() {
               Text('裁判需求: ').fontSize(12).fontColor('#999')
               Text('已申请裁判协助').fontSize(12).fontColor('#D94841').fontWeight(FontWeight.Bold)
             }
          }
        }
      }
      .margin({ bottom: 15 })

      Divider().margin({ bottom: 15 })

      Text('赛事详情 / 规则').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 5 })
      Scroll() {
        Text(this.t.description)
          .fontSize(14)
          .fontColor('#333')
          .lineHeight(20)
      }
      .height(100)
      .align(Alignment.TopStart)
      .margin({ bottom: 20 })

      // Actions
      Row() {
        if (this.t.isJoined) {
          Button('退赛 (Refund)')
            .backgroundColor('#D94841')
            .width('80%')
            .onClick(() => {
              this.onCancel();
              this.controller.close();
            })
        } else if (this.t.status === TournamentStatus.REGISTERING) {
           Button(`报名参加 ${this.t.organizerId === this.currentUserId ? '(主办方免费)' : ''}`)
            .backgroundColor('#007DFF')
            .width('80%')
            .onClick(() => {
              this.onJoin();
              this.controller.close();
            })
        } else {
           Button('报名已截止 / 未开始')
            .backgroundColor('#CCC')
            .enabled(false)
            .width('80%')
        }
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

    }
    .padding(20)
    .width('90%')
    .backgroundColor('#FFF')
    .borderRadius(16)
  }

  @Builder InfoItem(label: string, value: string) {
    Column() {
      Text(label).fontSize(10).fontColor('#999').margin({ bottom: 2 })
      Text(value).fontSize(14).fontColor('#333').fontWeight(FontWeight.Medium)
    }.alignItems(HorizontalAlign.Start)
  }

  getStatusColor(status: TournamentStatus): string {
    switch (status) {
      case TournamentStatus.REGISTERING: return '#007DFF';
      case TournamentStatus.RUNNING: return '#FF9500';
      case TournamentStatus.FINISHED: return '#999999';
      case TournamentStatus.PENDING_APPROVAL: return '#FF9F43';
      default: return '#999999';
    }
  }
}