import { RentableDeck, DeckComposition } from '../../model/RentableDeck';

@CustomDialog
export struct EditDeckDialog {
  @State deckName: string = '';
  @State deckFee: number = 0;
  @State deckDeposit: number = 0; 
  @State deckStock: number = 0;
  @State deckCover: string = ''; // [New]
  @State mainDeckCards: string[] = [];
  @State tags: string[] = []; 
  
  @State newCardName: string = '';
  @State newTagName: string = '';
  
  targetDeck: RentableDeck | null = null;
  // Updated signature
  confirmAction: (name: string, fee: number, deposit: number, stock: number, tags: string[], composition: string, cover: string) => void = () => {};
  controller: CustomDialogController;

  aboutToAppear() {
    if (this.targetDeck) {
      this.deckName = this.targetDeck.name;
      this.deckFee = this.targetDeck.rentalFeePerHour;
      this.deckDeposit = this.targetDeck.deposit || 0;
      this.deckStock = this.targetDeck.stock;
      this.deckCover = this.targetDeck.coverImage || '';
      this.tags = [...(this.targetDeck.tags || [])];
      if (this.targetDeck.composition && this.targetDeck.composition.main) {
        this.mainDeckCards = [...this.targetDeck.composition.main];
      }
    }
  }

  addCard() {
    if (this.newCardName.trim()) {
      this.mainDeckCards.push(this.newCardName.trim());
      this.newCardName = '';
    }
  }
  
  addTag() {
    if (this.newTagName.trim()) {
      if (!this.tags.includes(this.newTagName.trim())) {
        this.tags.push(this.newTagName.trim());
      }
      this.newTagName = '';
    }
  }

  removeCard(index: number) {
    this.mainDeckCards.splice(index, 1);
  }
  
  removeTag(index: number) {
    this.tags.splice(index, 1);
  }

  build() {
    Column({ space: 15 }) {
      Text('编辑卡组信息').fontSize(18).fontWeight(FontWeight.Bold)
      
      // 基础信息区
      Column({ space: 10 }) {
        TextInput({ placeholder: '卡组名称', text: this.deckName })
          .onChange((val) => this.deckName = val)
        
        TextInput({ placeholder: '封面图 (资源路径 or URL)', text: this.deckCover })
          .onChange((val) => this.deckCover = val)

        Row() {
          Text('租金/时: ').width(80)
          TextInput({ placeholder: '0', text: this.deckFee.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((val) => this.deckFee = parseInt(val) || 0)
        }
        
        Row() {
          Text('押金: ').width(80)
          TextInput({ placeholder: '0', text: this.deckDeposit.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((val) => this.deckDeposit = parseInt(val) || 0)
        }

        Row() {
          Text('库存量: ').width(80)
          TextInput({ placeholder: '0', text: this.deckStock.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((val) => this.deckStock = parseInt(val) || 0)
        }
        
        // Tags UI
        Column() {
          Text('标签 (Tags)').fontSize(12).fontColor('#666').width('100%').margin({bottom: 4})
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.tags, (tag: string, index: number) => {
              Row() {
                Text(tag).fontSize(10).fontColor('#007DFF')
                Text('×').fontSize(10).fontColor('#007DFF').margin({left: 4}).onClick(() => this.removeTag(index))
              }
              .padding({left: 6, right: 6, top: 2, bottom: 2})
              .backgroundColor('#E3F2FD')
              .borderRadius(4)
              .margin({right: 5, bottom: 5})
            })
            
            // Add Tag Input
            Row() {
              TextInput({ placeholder: '+', text: this.newTagName })
                .width(60).height(24).fontSize(10)
                .onChange((v) => this.newTagName = v)
                .onSubmit(() => this.addTag())
              Text('OK').fontSize(10).fontColor('#28C76F').margin({left: 4}).onClick(() => this.addTag())
            }
          }
        }
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#F9F9F9')
      .borderRadius(8)

      // 构筑编辑区
      Column() {
        Text('主卡组编辑 (Main Deck)').fontSize(14).fontWeight(FontWeight.Bold).margin({ bottom: 8 }).width('100%')
        
        // 卡片列表
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.mainDeckCards, (card: string, index: number) => {
            Row() {
              Text(card).fontSize(12).fontColor('#333')
              Text('×')
                .fontSize(14).fontColor('#D94841').fontWeight(FontWeight.Bold)
                .margin({ left: 6 })
                .onClick(() => this.removeCard(index))
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#EEE')
            .borderRadius(12)
            .margin({ right: 6, bottom: 6 })
          })
        }
        .width('100%')
        .constraintSize({ minHeight: 60, maxHeight: 150 }) // 限制高度

        // 添加卡片
        Row() {
          TextInput({ placeholder: '输入卡名添加', text: this.newCardName })
            .layoutWeight(1)
            .height(36)
            .onChange((val) => this.newCardName = val)
            .onSubmit(() => this.addCard()) // 回车也可添加
          
          Button('添加')
            .height(36)
            .margin({ left: 8 })
            .onClick(() => this.addCard())
        }.width('100%').margin({ top: 8 })
      }
      .width('100%')
      .padding(10)
      .border({ width: 1, color: '#EEE', radius: 8 })

      // 底部按钮
      Row() {
        Button('取消')
          .onClick(() => this.controller.close())
          .backgroundColor('#CCC')
          .width('40%')
        Blank()
        Button('保存')
          .onClick(() => {
            // 构建新的 composition JSON
            const newComp: DeckComposition = {
              main: this.mainDeckCards,
              extra: this.targetDeck?.composition?.extra || [],
              side: this.targetDeck?.composition?.side || []
            };
            this.confirmAction(
              this.deckName, 
              this.deckFee, 
              this.deckDeposit, 
              this.deckStock, 
              this.tags,
              JSON.stringify(newComp),
              this.deckCover
            );
            this.controller.close();
          })
          .width('40%')
      }.width('100%').margin({ top: 5 })
    }
    .padding(20)
    .backgroundColor('#FFF')
    .borderRadius(12)
    .width('95%') // 稍微加宽一点
  }
}