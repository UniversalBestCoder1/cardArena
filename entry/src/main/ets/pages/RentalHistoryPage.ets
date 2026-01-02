import router from '@ohos.router';
import DBHelper from '../common/DBHelper';

interface RentalRecord {

  id: number;

  deckName: string;

  time: string;

  status: number; // [新增]

}



interface TempRecord {

  deckId: string;

  time: string;

  status: number; // [新增]

}



@Entry

@Component

struct RentalHistoryPage {

  @State records: RentalRecord[] = [];



  async aboutToAppear() {

    // 1. 先把所有卡组名字查出来，做成 Map

    const deckRs = await DBHelper.query('decks');

    const deckMap: Record<string, string> = {};

    if (deckRs) {

      while (deckRs.goToNextRow()) {

        const id = deckRs.getString(deckRs.getColumnIndex('id'));

        const name = deckRs.getString(deckRs.getColumnIndex('name'));

        deckMap[id] = name;

      }

      deckRs.close();

    }



    // 2. 查租借表

    const rs = await DBHelper.query('rentals');

    const tempRecords: TempRecord[] = [];

    if (rs) {

      while (rs.goToNextRow()) {

        tempRecords.push({

          deckId: rs.getString(rs.getColumnIndex('deck_id')),

          time: new Date(rs.getLong(rs.getColumnIndex('rent_time'))).toLocaleString(),

          status: rs.getLong(rs.getColumnIndex('status')) // 读取状态

        });

      }

      rs.close();

    }



    // 3. 组装数据

    this.records = tempRecords.map((r, index) => {

      const record: RentalRecord = {

        id: index,

        deckName: deckMap[r.deckId] || `未知卡组 (${r.deckId})`,

        time: r.time,

        status: r.status

      };

      return record;

    });

  }



  build() {

    Column() {

      Row() {

        Image($r('app.media.mtga_icon')).width(24).height(24).onClick(() => router.back())

        Text('租借记录').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })

      }

      .width('100%').padding(15).backgroundColor('#FFF')



      List() {

        if (this.records.length === 0) {

          ListItem() { Text('暂无租借记录').width('100%').textAlign(TextAlign.Center).margin({ top: 50 }).fontColor('#999') }

        }

        ForEach(this.records, (item: RentalRecord) => {

          ListItem() {

            Row() {

              Column() {

                Text(item.deckName).fontSize(16).fontWeight(FontWeight.Bold)

                Text(item.time).fontSize(12).fontColor('#999').margin({ top: 5 })

              }

              .alignItems(HorizontalAlign.Start)

              

              Blank()

              

              // 状态标签

              Text(item.status === 0 ? '租用中' : '已归还')

                .fontSize(12)

                .fontColor('#FFF')

                .backgroundColor(item.status === 0 ? '#FF9F43' : '#CCC') // 橙色/灰色

                .padding({ left: 8, right: 8, top: 4, bottom: 4 })

                .borderRadius(4)

            }

            .width('100%').padding(15).backgroundColor('#FFF').margin({ bottom: 1 })

          }

        })

      }

      .width('100%').layoutWeight(1)

    }

    .width('100%').height('100%').backgroundColor('#F1F3F5')

  }

}
