import router from '@ohos.router';
import { Card } from '../model/Card';

@Entry
@Component
struct CardDetailPage {
  @State card: Card | null = null;

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['card']) {
      this.card = params['card'] as Card;
    }
  }

  build() {
    Column() {
      // 1. 顶部导航
      Row() {
        Button(' < 返回')
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .fontColor('#333')
          .onClick(() => router.back())
        
        Text(this.card?.name || '卡牌详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .padding({ right: 40 }) // 视觉平衡
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFF')
      .zIndex(10)

      Scroll() {
        Column() {
          if (this.card) {
            // 2. 卡图区域
            Image(this.card.imageUrl.startsWith('http') ? this.card.imageUrl : $r(this.card.imageUrl))
              .alt($r('app.media.mtga_icon'))
              .width('80%')
              .height(400) // 大图展示
              .objectFit(ImageFit.Contain)
              .margin({ top: 20, bottom: 20 })
              .shadow({ radius: 10, color: '#33000000', offsetY: 5 })

            // 3. 信息卡片
            Column() {
              // 标题与稀有度
              Row() {
                Text(this.card.name)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                
                Text(this.card.rarity)
                  .fontSize(14)
                  .fontColor('#FFF')
                  .backgroundColor('#D4AF37') // 金色背景
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(4)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Divider().margin({ top: 10, bottom: 10 })

              // 属性信息 (YGO特有)
              if (this.card.gameType.includes('YGO')) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  this.TagItem(`Type: ${this.card.type}`)
                  if (this.card.atk !== undefined) this.TagItem(`ATK: ${this.card.atk}`, '#D94841')
                  if (this.card.def !== undefined) this.TagItem(`DEF: ${this.card.def}`, '#007DFF')
                  if (this.card.attribute) this.TagItem(`Attr: ${this.card.attribute}`)
                  if (this.card.race) this.TagItem(`Race: ${this.card.race}`)
                }
                .margin({ bottom: 10 })
              } else {
                // MTG 特有
                Text(`类别: ${this.card.type}`)
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ bottom: 10 })
              }

              // 效果文本
              Text('【效果 / 描述】')
                .fontSize(14)
                .fontColor('#999')
                .margin({ bottom: 4 })
              
              Text(this.card.description)
                .fontSize(16)
                .lineHeight(24)
                .fontColor('#333')
                .backgroundColor('#F9F9F9')
                .padding(10)
                .borderRadius(8)
                .width('100%')

              Divider().margin({ top: 10, bottom: 10 })

              // 价格信息
              Row() {
                Text('参考均价')
                  .fontSize(14)
                  .fontColor('#666')
                Blank()
                Text(`￥${this.card.priceAvg.toFixed(1)}`)
                  .fontSize(24)
                  .fontColor('#FF0033')
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .padding({ top: 10 })

            }
            .width('95%')
            .backgroundColor('#FFF')
            .borderRadius(16)
            .padding(16)
            .shadow({ radius: 5, color: '#11000000', offsetY: 2 })
          } else {
            LoadingProgress()
          }
        }
        .width('100%')
        .padding({ bottom: 50 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder TagItem(text: string, color: string = '#666') {
    Text(text)
      .fontSize(12)
      .fontColor(color)
      .backgroundColor('#EEE')
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(12)
      .margin({ right: 8, bottom: 8 })
  }
}

