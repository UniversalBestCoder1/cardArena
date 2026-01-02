import { MockService } from '../mock/MockService';
import { Tournament, TournamentStatus, OrganizerType } from '../model/Tournament';
import promptAction from '@ohos.promptAction';
import { TournamentDetailDialog } from './TournamentDetailDialog';
import { User } from '../model/User';
import { SmartIcon } from '../common/SmartIcon'; // [New]

@Component
export struct HomeView {
  @State tournamentList: Tournament[] = [];
  
  // Dialog Controller
  detailController: CustomDialogController | null = null;
  @State selectedTournament: Tournament | null = null;
  @State currentUser: User | null = null;
  @State lfgPlayers: User[] = []; // [New]

  aboutToAppear() {
    this.currentUser = MockService.getCurrentUser();
    this.loadData();
    this.loadLfg();
  }

  async loadData() {
    this.tournamentList = await MockService.getTournaments();
    this.currentUser = MockService.getCurrentUser();
  }
  
  async loadLfg() {
    this.lfgPlayers = await MockService.getOnlinePlayers();
  }

  async toggleLfg(status: 'IDLE' | 'LFG_YGO' | 'LFG_MTG' | 'LFG_EDH') {
    let msg = '';
    if (status !== 'IDLE') {
       // Simple prompt for message? For now hardcode or random for speed
       msg = '来把痛快的决斗！'; 
    }
    await MockService.updateLfgStatus(status, msg);
    this.currentUser = MockService.getCurrentUser(); // Refresh local
    await this.loadLfg(); // Refresh list
  }

  openDetail(t: Tournament) {
    this.selectedTournament = t;
    this.detailController = new CustomDialogController({
      builder: TournamentDetailDialog({
        t: this.selectedTournament,
        currentUserId: this.currentUser?.id || '',
        onJoin: () => this.handleJoin(t),
        onCancel: () => this.handleCancel(t),
        controller: undefined
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.detailController.open();
  }

  async handleJoin(t: Tournament): Promise<void> {
    const isOrganizer = this.currentUser?.id === t.organizerId;
    const feeMsg = isOrganizer ? '您是主办方，可免费参加。' : `报名 "${t.title}" 需要扣除 ${t.entryFee} 积分。`;

    AlertDialog.show({
      title: '确认报名',
      message: `${feeMsg}\n确定继续吗？`,
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认参加',
        fontColor: '#007DFF',
        action: async () => {
          const success = await MockService.joinTournament(t.id);
          
          if (success) {
            promptAction.showToast({ message: '报名成功！', duration: 2000 });
            await this.loadData();
          } else {
            AlertDialog.show({ title: '报名失败', message: '积分不足或已满员。' });
          }
        }
      }
    });
  }

  async handleCancel(t: Tournament): Promise<void> {
    AlertDialog.show({
      title: '确认退赛',
      message: `退赛后将返还 ${t.entryFee} 积分。
确定要放弃参赛吗？`,
      primaryButton: {
        value: '我再想想',
        action: () => {}
      },
      secondaryButton: {
        value: '确定退赛',
        fontColor: '#D94841',
        action: async () => {
          const success = await MockService.cancelTournament(t.id);
          if (success) {
            promptAction.showToast({ message: '已退赛，积分已返还。', duration: 2000 });
            await this.loadData();
          } else {
            promptAction.showToast({ message: '退赛失败' });
          }
        }
      }
    });
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('决斗者链接 - 线下版')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        // 模拟定位
        Text('📍 北京·鼓楼店')
          .fontSize(12)
          .fontColor('#666')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFF')

      // 赛事列表
      List({ space: 12 }) {
        // [New] LFG Radar Section
        ListItem() {
          Column() {
            Row() {
              Text('约战雷达').fontSize(16).fontWeight(FontWeight.Bold)
              Blank()
              // Status Toggle
              if (this.currentUser?.lfgStatus && this.currentUser.lfgStatus !== 'IDLE') {
                 Button('停止寻找')
                  .height(28).fontSize(12).backgroundColor('#D94841')
                  .onClick(() => this.toggleLfg('IDLE'))
              } else {
                 Row() {
                   Button('找YGO').height(28).fontSize(12).margin({right: 5}).onClick(() => this.toggleLfg('LFG_YGO'))
                   Button('找MTG').height(28).fontSize(12).margin({right: 5}).onClick(() => this.toggleLfg('LFG_MTG'))
                   Button('找EDH').height(28).fontSize(12).onClick(() => this.toggleLfg('LFG_EDH'))
                 }
              }
            }.width('100%').margin({ bottom: 10 })
            
            if (this.lfgPlayers.length > 0) {
               List({ space: 8 }) {
                 ForEach(this.lfgPlayers, (p: User) => {
                   ListItem() {
                     Row() {
                        // Avatar
                        SmartIcon({ name: p.username, iconSize: 30 })
                          .margin({right: 8})
                        
                        Column() {
                          Text(p.username).fontSize(14).fontWeight(FontWeight.Bold)
                          Text(p.lfgMessage).fontSize(10).fontColor('#666')
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                        
                        Text(p.lfgStatus?.replace('LFG_', ''))
                          .fontSize(10).fontColor('#FFF').backgroundColor('#007DFF')
                          .padding({left:4, right:4, top:2, bottom:2}).borderRadius(4)
                        
                        Button('邀请')
                          .height(24).fontSize(10).backgroundColor('#28C76F').margin({left: 5})
                          .onClick(() => {
                             promptAction.showToast({ message: `已向 ${p.username} 发送对战邀请` })
                          })
                     }
                     .width('100%').padding(10).backgroundColor('#F9F9F9').borderRadius(8)
                   }
                 })
               }
            } else {
               Text('附近暂时没有人在寻找对手...').fontSize(12).fontColor('#999').margin({bottom: 10})
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFF')
          .borderRadius(12)
          .shadow({ radius: 8, color: '#0F000000', offsetY: 4 })
        }

        ForEach(this.tournamentList, (item: Tournament) => {
          ListItem() {
            this.TournamentCard(item)
          }
        }, (item: Tournament) => `${item.id}_${item.isJoined}_${item.currentPlayers}`) 
      }
      .layoutWeight(1)
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder TournamentCard(t: Tournament) {
    Column() {
      // 赛事海报 (Banner)
      if (t.poster) {
        if (t.poster === 'app.media.ygo_poster') {
           Image($r('app.media.ygo_poster'))
            .width('100%')
            .height(100)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 12, topRight: 12 })
            .margin({ bottom: 8 })
        } else if (t.poster === 'app.media.mtg_poster') {
           Image($r('app.media.mtg_poster'))
            .width('100%')
            .height(100)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 12, topRight: 12 })
            .margin({ bottom: 8 })
        } else {
           // User selected URI or URL
           Image(t.poster)
            .width('100%')
            .height(100)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 12, topRight: 12 })
            .margin({ bottom: 8 })
        }
      }

      // 内容容器 (padding move here to not clip image)
      Column() {
        // 顶部：状态与时间 (使用 Flex 避免右侧溢出)
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          // 左侧: 状态 + 时间
          Row() {
            Text(t.status)
              .fontSize(10)
              .fontColor('#FFF')
              .backgroundColor(this.getStatusColor(t.status))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
            
            Text(t.startTime)
              .fontSize(12)
              .fontColor('#999')
              .margin({ left: 8 })
          }

          // 右侧: 游戏类型 + 举办者
          Row() {
            Text(t.gameType.includes('YGO') ? 'YGO' : 'MTG')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .margin({ right: 6 })

            if (t.organizerType === OrganizerType.SHOP) {
              Text('官方')
                .fontSize(10)
                .fontColor('#FFF')
                .backgroundColor('#7367F0')
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(3)
            } else {
              Text('玩家')
                .fontSize(10)
                .fontColor('#FFF')
                .backgroundColor('#FF9F43')
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(3)
            }
          }
        }
        .width('100%')

        // 标题与详情
        Text(t.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 8, bottom: 4 })
        
        Text(`赛制: ${t.format}`)
          .fontSize(12)
          .fontColor('#007DFF')
          .margin({ bottom: 4 })

        Text(`地点: ${t.location} | 费用: ${t.entryFee} 积分`)
          .fontSize(12)
          .fontColor('#666')

        if (t.organizerType === OrganizerType.PLAYER && t.requireReferee) {
          Row() {
             Text('需要裁判')
              .fontSize(10)
              .fontColor('#EA5455')
              .border({ width: 1, color: '#EA5455' })
              .padding({ left: 4, right: 4 })
              .borderRadius(2)
          }
          .margin({ top: 4 })
        }
        
        Text(t.description)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 4 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Divider().color('#EEE').margin({ top: 10, bottom: 10 })

        // 底部：报名信息
        Row() {
          Column() {
            Text(`${t.currentPlayers}/${t.maxPlayers}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('已报名')
              .fontSize(10)
              .fontColor('#999')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          if (t.isJoined) {
            Button('退赛 (Refund)')
              .fontSize(12)
              .backgroundColor('#FFF')
              .fontColor('#D94841')
              .border({ width: 1, color: '#D94841' })
              .onClick(() => this.handleCancel(t)) 
          } else if (t.status === TournamentStatus.REGISTERING) {
            Button('详情 / 报名')
              .fontSize(12)
              .backgroundColor('#007DFF')
              .onClick(() => this.openDetail(t)) 
          } else {
             Button('查看详情')
              .fontSize(12)
              .backgroundColor('#CCC')
              .fontColor('#333')
              .onClick(() => this.openDetail(t))
          }
        }
        .width('100%')
      }
      .padding(12) // Moved padding here
    }
    .width('100%')
    // Remove outer padding(12) to allow image to flush
    .backgroundColor('#FFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#0F000000', offsetY: 4 })
    .onClick(() => this.openDetail(t)) 
  }

  getStatusColor(status: TournamentStatus): string {
    switch (status) {
      case TournamentStatus.REGISTERING: return '#007DFF'; // 蓝
      case TournamentStatus.RUNNING: return '#FF9500'; // 橙
      case TournamentStatus.FINISHED: return '#999999'; // 灰
      default: return '#999999';
    }
  }
}
