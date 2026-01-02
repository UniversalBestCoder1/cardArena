import { RentableDeck } from '../model/RentableDeck';
import { SmartIcon } from '../common/SmartIcon';

@CustomDialog
export struct DeckDetailDialog {
  deck: RentableDeck | null = null;
  controller: CustomDialogController;

  build() {
    Column() {
      if (this.deck) {
        // ... (Header logic remains) ...
        Row() {
          SmartIcon({ name: this.deck.name, iconSize: 40 })
          Column() {
            Text(this.deck.name)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Text(`押金: ${this.deck.deposit || 0} 积分`)
              .fontSize(12)
              .fontColor('#FF9500')
              .margin({ top: 4 })
          }
          .margin({ left: 10 })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ bottom: 10 })
        .border({ width: { bottom: 1 }, color: '#EEE' })

        // [New] Visualization Section
        if (this.deck.composition && this.deck.composition.main.length > 0) {
           this.DeckStats(this.deck.gameType)
        }

        Scroll() {
          // ... (Card list) ...
          Column() {
            if (this.deck.composition) {
              this.CardSection('主卡组 (Main Deck)', this.deck.composition.main)
              if (this.deck.composition.extra && this.deck.composition.extra.length > 0) {
                this.CardSection('额外卡组 (Extra Deck)', this.deck.composition.extra)
              }
              if (this.deck.composition.side && this.deck.composition.side.length > 0) {
                this.CardSection('副卡组 (Side Deck)', this.deck.composition.side)
              }
            } else {
              Text('暂无构筑详情').fontColor('#999').margin({ top: 20 })
            }
          }
          .width('100%')
        }
        .layoutWeight(1) // Use layoutWeight instead of fixed height
      }
    }
    .padding(20)
    .backgroundColor('#FFF')
    .borderRadius(12)
    .width('90%')
    .height('70%') // Taller dialog
  }

  @Builder DeckStats(gameType: string) {
    Column() {
      Text('构筑分析').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({top: 10, bottom: 5})
      
      if (gameType === 'YGO') {
        // Simple Bar Chart for YGO (Monster/Spell/Trap) - Mocked ratios
        Row() {
          this.StatBar('怪兽', 20, '#F5C518') // Yellow
          this.StatBar('魔法', 12, '#28C76F') // Green
          this.StatBar('陷阱', 8, '#EA5455')  // Red
        }.width('100%').height(20).margin({bottom: 10})
        
        Row() {
           Text('怪兽: 20').fontSize(10).fontColor('#666').margin({right: 10})
           Text('魔法: 12').fontSize(10).fontColor('#666').margin({right: 10})
           Text('陷阱: 8').fontSize(10).fontColor('#666')
        }
      } else {
        // Simple Mana Curve for MTG
        Row() {
          this.CurveBar(1, 4)
          this.CurveBar(2, 8)
          this.CurveBar(3, 10)
          this.CurveBar(4, 6)
          this.CurveBar(5, 4)
          this.CurveBar(6, 2)
        }
        .width('100%')
        .height(60)
        .margin({bottom: 5})
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Bottom)
        
        Text('法术力曲线 (Mana Curve)').fontSize(10).fontColor('#999')
      }
    }
    .padding(10).backgroundColor('#F9F9F9').borderRadius(8).width('100%').margin({bottom: 10})
  }

  @Builder StatBar(label: string, count: number, color: string) {
    // Just a visual representation, total 40
    Row().width(`${(count/40)*100}%`).height('100%').backgroundColor(color)
  }

  @Builder CurveBar(cost: number, count: number) {
    Column() {
      // Bar height relative to max (e.g. 10)
      Column().width(15).height(`${(count/12)*100}%`).backgroundColor('#007DFF').borderRadius({topLeft: 4, topRight: 4})
      Text(cost + '').fontSize(10).margin({top: 2})
    }.height('100%').justifyContent(FlexAlign.End)
  }

  @Builder CardSection(title: string, cards: string[]) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#007DFF')
        .margin({ top: 15, bottom: 5 })
        .width('100%')
      
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(cards, (card: string) => {
          Text(card)
            .fontSize(12)
            .fontColor('#333')
            .backgroundColor('#F5F5F5')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(4)
            .margin({ right: 6, bottom: 6 })
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}