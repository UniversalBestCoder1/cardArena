import router from '@ohos.router';
import { TournamentService } from '../service/TournamentService';
import { AuthService } from '../service/AuthService';
import { Tournament, TournamentStatus, TournamentRound, MatchPairing, OrganizerType } from '../model/Tournament';
import { ChatView } from './ChatView'; 
import { User } from '../model/User'; 

@Component
export struct AdminDashboardView {
  @State activeTournaments: Tournament[] = [];
  @State selectedTournament: Tournament | null = null;
  @State currentNav: string = '赛事管理';
  
  // [New] Player List State
  @State tournamentPlayers: User[] = [];
  
  // 获取当前角色
  @StorageLink('userRole') userRole: string = 'MANAGER';

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    // 获取所有比赛
    const all = await TournamentService.getTournaments();
    // Manager sees all, Staff/Player might see filtered? 
    // Assuming Dashboard is for Manager/Staff primarily.
    this.activeTournaments = all;
  }

  async loadPlayers(tId: string) {
    this.tournamentPlayers = await TournamentService.getTournamentPlayers(tId);
  }
  
  async handleApprove(t: Tournament) {
    await TournamentService.approveTournament(t.id);
    await this.loadData();
    if(this.selectedTournament?.id === t.id) this.selectedTournament = null;
  }

  async handleReject(t: Tournament) {
    await TournamentService.rejectTournament(t.id);
    await this.loadData();
    if(this.selectedTournament?.id === t.id) this.selectedTournament = null;
  }

  async handleKick(u: User) {
    if (!this.selectedTournament) return;
    
    // Safety check for Manager restriction
    if (this.userRole === 'MANAGER' && this.selectedTournament.organizerType === OrganizerType.PLAYER) {
      AlertDialog.show({ message: '店长无权干涉玩家自办赛事的参赛人员。' });
      return;
    }

    AlertDialog.show({
       title: '踢出玩家',
       message: `确定要将 ${u.username} 移出比赛吗？\n报名费将自动退还。`,
       primaryButton: { value: '取消', action: () => {} },
       secondaryButton: { 
         value: '踢出', 
         fontColor: '#D94841',
         action: async () => {
           if (this.selectedTournament) {
             const success = await TournamentService.kickPlayer(this.selectedTournament.id, u.id);
             if (success) {
               this.loadPlayers(this.selectedTournament.id);
               // Refresh tournament data to update counts
               this.loadData();
             } else {
               AlertDialog.show({ message: '操作失败 (权限不足或系统错误)' });
             }
           }
         }
       }
    });
  }

  // [核心功能] 模拟瑞士轮排表算法
  startNextRound(t: Tournament) {
    if (!t.rounds) t.rounds = [];
    const nextRoundNum = t.rounds.length + 1;
    
    // 模拟排表逻辑 (随机配对)
    const newRound: TournamentRound = {
      roundNumber: nextRoundNum,
      pairings: [
        { tableNo: 1, playerA: '张三', playerB: '李四', scoreA: 0, scoreB: 0 },
        { tableNo: 2, playerA: '王五', playerB: '赵六', scoreA: 0, scoreB: 0 },
        { tableNo: 3, playerA: '决斗者K', playerB: '轮空', scoreA: 2, scoreB: 0, winner: '决斗者K' }
      ]
    };

    t.rounds.push(newRound);
    t.status = TournamentStatus.RUNNING;
    
    // 强制刷新 UI
    const index = this.activeTournaments.findIndex(item => item.id === t.id);
    if (index !== -1) {
      this.activeTournaments[index] = JSON.parse(JSON.stringify(t)); 
      this.selectedTournament = this.activeTournaments[index];
    }

    AlertDialog.show({ message: `第 ${nextRoundNum} 轮排表完成！请通知选手就位。` });
  }

  // [新增] 删除赛事
  async handleDelete(t: Tournament) {
    if (this.userRole !== 'MANAGER') {
      AlertDialog.show({ message: '权限不足：只有店长可以删除赛事。' });
      return;
    }

    AlertDialog.show({
      title: '删除确认',
      message: `确定要删除 "${t.title}" 吗？此操作不可恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#D94841',
        action: async () => {
          await TournamentService.deleteTournament(t.id);
          this.selectedTournament = null;
          await this.loadData();
        }
      }
    });
  }

  build() {
    Row() {
      // --- 左侧导航栏 ---
      Column() {
        Text(`${this.userRole === 'MANAGER' ? '店长' : '员工'}\n控制台`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .margin({ top: 30, bottom: 30 })
        
        this.NavButton('赛事管理')
        this.NavButton('顾客沟通')
        
        // 权限控制：仅店长可见
        if (this.userRole === 'MANAGER') {
          this.NavButton('库存监控')
          this.NavButton('财务报表')
        }
        
        Blank()
        
        Button('退出登录')
          .backgroundColor('#D94841')
          .margin({ bottom: 20 })
          .onClick(() => {
            AuthService.logout();
            router.replaceUrl({ url: 'pages/LoginPage' });
          })
      }
      .width(100)
      .height('100%')
      .backgroundColor('#EEE')

      // --- 右侧内容区 ---
      Column() {
        if (this.currentNav === '赛事管理') {
           if (!this.selectedTournament) {
              
              // [New] Pending Requests Section
              if (this.activeTournaments.some(t => t.status === TournamentStatus.PENDING_APPROVAL)) {
                Text('待审核申请')
                  .fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 10 }).width('100%')
                
                List({ space: 10 }) {
                  ForEach(this.activeTournaments.filter(t => t.status === TournamentStatus.PENDING_APPROVAL), (t: Tournament) => {
                    ListItem() {
                      Row() {
                        Column() {
                          Text(t.title).fontWeight(FontWeight.Bold)
                          Text(`主办: ${t.organizerName} | 费用: ${t.entryFee}`).fontSize(12).fontColor('#666')
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                        
                        Button('拒绝').backgroundColor('#D94841').height(28).fontSize(12).margin({right: 5})
                          .onClick(() => this.handleReject(t))
                        Button('通过').backgroundColor('#28C76F').height(28).fontSize(12)
                          .onClick(() => this.handleApprove(t))
                      }
                      .width('100%').padding(15).backgroundColor('#FFF').borderRadius(8)
                    }
                  })
                }.margin({ bottom: 20 })
              }

              Text('赛事列表')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })
                .width('100%')

              List({ space: 10 }) {
                ForEach(this.activeTournaments.filter(t => t.status !== TournamentStatus.PENDING_APPROVAL && t.status !== TournamentStatus.REJECTED), (t: Tournament) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Row() {
                          if (t.organizerType === OrganizerType.PLAYER) {
                            Text('玩家')
                              .fontSize(10).fontColor('#FFF').backgroundColor('#FF9F43')
                              .padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(3)
                              .margin({ right: 5 })
                              .flexShrink(0) // 防止标签被压缩
                          }
                          Text(t.title)
                            .fontWeight(FontWeight.Bold)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .width('100%') // 确保 Row 填满 Column 宽度
                        
                        Text(`赛制: ${t.format} | 状态: ${t.status}`)
                          .fontSize(12).fontColor('#666').margin({ top: 4 })
                          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1) // 关键：占据剩余空间
                      .margin({ right: 10 })
                      
                      Button('管理')
                        .height(30)
                        .fontSize(12)
                        .flexShrink(0) // 防止按钮被压缩
                        .onClick(() => {
                           this.selectedTournament = t;
                           this.loadPlayers(t.id);
                        })
                    }
                    .width('100%')
                    .padding(15)
                    .backgroundColor('#FFF')
                    .borderRadius(8)
                    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
                  }
                }, (t: Tournament) => t.id)
              }
           } else {
              this.TournamentManager(this.selectedTournament)
           }
        } else if (this.currentNav === '顾客沟通') {
          // [新增] 聊天视图
          ChatView()
        }
      }
      .layoutWeight(1)
      .height('100%')
      .padding(20)
      .backgroundColor('#F1F3F5')
    }
    .height('100%')
  }

  @Builder NavButton(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(this.currentNav === text ? '#007DFF' : '#666')
      .backgroundColor(this.currentNav === text ? '#FFF' : 'transparent')
      .width('100%')
      .padding(15)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        if (text === '库存监控') {
          router.pushUrl({ url: 'pages/AdminInventoryPage' });
        } else if (text === '财务报表') {
          router.pushUrl({ url: 'pages/AdminFinancePage' });
        } else {
          this.currentNav = text;
        }
      })
  }

  @Builder TournamentManager(t: Tournament) {
    Column() {
      Row() {
        Button('< 返回列表').onClick(() => this.selectedTournament = null).height(30).backgroundColor('#999')
        Blank()
        Text(t.title).fontSize(18).fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 赛事详情卡片
      Column() {
        Row() {
          Text('基本信息').fontWeight(FontWeight.Bold)
        }.width('100%').margin({ bottom: 8 })

        GridRow({ columns: 2, gutter: 10 }) {
          GridCol() { Text(`主办方: ${t.organizerName} (${t.organizerType})`).fontSize(12) }
          GridCol() { Text(`赛制: ${t.format}`).fontSize(12) }
          GridCol() { Text(`时间: ${t.startTime}`).fontSize(12) }
          GridCol() { Text(`费用: ￥${t.entryFee}`).fontSize(12) }
          GridCol() { Text(`裁判需求: ${t.requireReferee ? '需要' : '不需要'}`).fontSize(12).fontColor(t.requireReferee ? '#D94841' : '#333') }
          GridCol() { Text(`卡组限制: ${t.allowedDecks}`).fontSize(12) }
        }
      }
      .padding(15)
      .backgroundColor('#FFF')
      .borderRadius(8)
      .width('100%')
      .margin({ bottom: 20 })
      
      // [New] 参赛玩家管理
      Column() {
        Row() {
          Text(`参赛玩家 (${this.tournamentPlayers.length}/${t.maxPlayers})`).fontWeight(FontWeight.Bold)
        }.width('100%').margin({ bottom: 8 })
        
        List({ space: 8 }) {
           ForEach(this.tournamentPlayers, (u: User) => {
             ListItem() {
               Row() {
                 Text(u.username).fontSize(14)
                 Blank()
                 if (this.userRole === 'MANAGER' && t.organizerType === OrganizerType.SHOP) {
                   Button('踢出')
                    .fontSize(10)
                    .height(20)
                    .backgroundColor('#D94841')
                    .onClick(() => this.handleKick(u))
                 } else if (this.userRole === 'MANAGER' && t.organizerType === OrganizerType.PLAYER) {
                   Text('无权踢出').fontSize(10).fontColor('#999')
                 }
               }.width('100%')
             }
           })
        }
        .constraintSize({ maxHeight: 100 })
      }
      .padding(15)
      .backgroundColor('#FFF')
      .borderRadius(8)
      .width('100%')
      .margin({ bottom: 20 })

      // 操作区
      Row() {
        Button('开始下一轮排表')
          .onClick(() => this.startNextRound(t))
          .backgroundColor('#007DFF')
          .margin({ right: 10 })
          
        // [New] 动态执裁入口：仅当赛事需要裁判时显示
        if (t.requireReferee) {
          Button('进入执裁')
            .backgroundColor('#F1C40F')
            .fontColor('#333')
            .onClick(() => {
               router.pushUrl({
                 url: 'pages/RefereePage',
                 params: {
                   tournamentId: t.id,
                   title: t.title
                 }
               });
            })
        }
        
        Blank()
        
        // 权限控制：删除按钮
        if (this.userRole === 'MANAGER') {
          Button('删除赛事')
            .backgroundColor('#D94841')
            .onClick(() => this.handleDelete(t))
        }
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 赛程显示
      if (t.rounds && t.rounds.length > 0) {
        List() {
          ForEach(t.rounds, (round: TournamentRound) => {
            ListItem() {
              Column() {
                Text(`--- 第 ${round.roundNumber} 轮对阵 ---`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 10 })
                
                ForEach(round.pairings, (pair: MatchPairing) => {
                  Row() {
                    Text(`${pair.tableNo}桌`).fontColor('#999').width(40)
                    Text(pair.playerA).width(80).textAlign(TextAlign.End)
                    Text(' vs ').fontColor('#DDD')
                    Text(pair.playerB).width(80)
                    Blank()
                    Button('录入')
                      .height(24)
                      .fontSize(10)
                      .backgroundColor('#28C76F')
                      .onClick(() => {
                         AlertDialog.show({ message: '录入比分功能演示：\n请选择胜者：PlayerA / PlayerB' })
                      })
                  }
                  .width('100%')
                  .padding({ top: 8, bottom: 8 })
                  .border({ width: { bottom: 1 }, color: '#EEE' })
                })
              }
              .padding(15)
              .backgroundColor('#FFF')
              .borderRadius(8)
              .margin({ bottom: 10 })
            }
          })
        }
        .layoutWeight(1)
      } else {
        Column() {
          Text('暂无赛程数据，请点击“开始排表”').fontColor('#999')
        }
        .height(100)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
