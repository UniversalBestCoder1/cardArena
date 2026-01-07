import { Match, MatchStatus } from '../model/Match';
import { MatchService } from '../service/MatchService';
import router from '@ohos.router';

@Entry
@Component
struct RefereePage {
  @State matches: Match[] = [];
  @State tournamentId: string = '';
  @State tournamentTitle: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.tournamentId = params['tournamentId'];
      this.tournamentTitle = params['title'];
      this.loadMatches();
    }
  }

  async loadMatches() {
    this.matches = await MatchService.getMatches(this.tournamentId);
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.startIcon')) // Back arrow placeholder
          .width(24)
          .height(24)
          .onClick(() => router.back())
        
        Text(`裁判执裁: ${this.tournamentTitle}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#2D3436')

      List({ space: 12 }) {
        ForEach(this.matches, (match: Match) => {
          ListItem() {
            Column() {
              // 桌号
              Row() {
                Text(`Table ${match.tableNumber}`)
                  .fontColor('#A0A0A0')
                  .fontSize(14)
                
                if (match.status === MatchStatus.FINISHED) {
                  Text('已完赛')
                    .fontColor(Color.Green)
                    .fontSize(14)
                } else {
                  Text('进行中')
                    .fontColor(Color.Orange)
                    .fontSize(14)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 8 })

              // 选手与比分
              Row() {
                // Player A
                Column() {
                  Text(match.playerAName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(match.winnerId === 'playerA' ? Color.Green : Color.White)
                  Text('Player A')
                    .fontSize(12)
                    .fontColor('#808080')
                }.alignItems(HorizontalAlign.Start)

                // VS / Score
                if (match.status === MatchStatus.PENDING) {
                   Text('VS')
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#F1C40F')
                    .margin({ left: 20, right: 20 })
                } else {
                   Text(`${match.scoreA} : ${match.scoreB}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                    .margin({ left: 20, right: 20 })
                }

                // Player B
                Column() {
                  Text(match.playerBName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(match.winnerId === 'playerB' ? Color.Green : Color.White)
                  Text('Player B')
                    .fontSize(12)
                    .fontColor('#808080')
                }.alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ bottom: 12 })

              // 录入按钮
              if (match.status === MatchStatus.PENDING) {
                Button('录入成绩')
                  .width('100%')
                  .height(36)
                  .backgroundColor('#0984E3')
                  .onClick(() => {
                    this.showResultDialog(match);
                  })
              }
            }
            .padding(16)
            .backgroundColor('#363636')
            .borderRadius(12)
          }
        })
      }
      .layoutWeight(1)
      .padding(16)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1E1E1E')
  }

  // 简单的录入弹窗
  showResultDialog(match: Match) {
    AlertDialog.show({
      title: `录入成绩: 桌号 ${match.tableNumber}`,
      message: `${match.playerAName} vs ${match.playerBName}\n请选择胜者或具体比分`,
      primaryButton: {
        value: '2 : 0 (A胜)',
        action: async () => {
          await MatchService.submitResult(match.id, 2, 0);
          this.loadMatches();
        }
      },
      secondaryButton: {
        value: '0 : 2 (B胜)',
        action: async () => {
          await MatchService.submitResult(match.id, 0, 2);
          this.loadMatches();
        }
      },
      // 实际上应该有个更复杂的自定义 Dialog 输入 2:1 或 1:2，这里简化演示
      cancel: () => {}
    })
  }
}
