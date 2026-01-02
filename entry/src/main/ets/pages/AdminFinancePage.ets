import router from '@ohos.router';
import { FinanceService } from '../service/FinanceService';

@Entry
@Component
struct AdminFinancePage {
  @State totalRevenue: number = 0;
  @State incomeTournament: number = 0;
  @State incomeRental: number = 0;

  async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    const report = await FinanceService.getFinancialReport();
    this.totalRevenue = report.totalRevenue;
    this.incomeTournament = report.byType.tournament;
    this.incomeRental = report.byType.rental;
  }
// ... (rest of build method)

  build() {
    Column() {
      Row() {
        Image($r('app.media.mtga_icon')).width(24).height(24).onClick(() => router.back())
        Text('财务报表 (总览)').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })
      }
      .width('100%').padding(15).backgroundColor('#FFF')

      // 总收入
      Column() {
        Text('总营收净额').fontColor('#EEE')
        Text(`￥${this.totalRevenue.toFixed(2)}`).fontSize(36).fontColor('#FFF').fontWeight(FontWeight.Bold).margin({ top: 10 })
      }
      .width('90%').height(120).backgroundColor('#007DFF').borderRadius(16).justifyContent(FlexAlign.Center).margin({ top: 20 })

      // 占比分析
      Column() {
        Text('收入构成').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 15 }).width('100%')
        
        this.ChartItem('赛事报名费', this.incomeTournament, '#FF9F43')
        this.ChartItem('其他/租金', this.incomeRental, '#28C76F')
      }
      .width('90%').padding(20).backgroundColor('#FFF').borderRadius(16).margin({ top: 20 })
      
      Button('刷新数据')
        .margin({ top: 20 })
        .backgroundColor('#EEE').fontColor('#666')
        .onClick(() => this.loadData())
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }

  @Builder ChartItem(label: string, amount: number, color: string) {
    Column() {
      Row() {
        Text(label).fontSize(14)
        Blank()
        Text(`￥${amount.toFixed(2)}`).fontSize(14).fontWeight(FontWeight.Bold)
      }
      .width('100%').margin({ bottom: 5 })
      
      // 简单进度条示意
      Progress({ value: this.totalRevenue > 0 ? (amount / this.totalRevenue * 100) : 0, total: 100, type: ProgressType.Linear })
        .color(color)
        .width('100%')
    }
    .margin({ bottom: 20 })
  }
}
