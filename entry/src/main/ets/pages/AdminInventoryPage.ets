import router from '@ohos.router';
import DBHelper from '../common/DBHelper';
import { RentableDeck, DeckComposition } from '../model/RentableDeck';
import { MockService } from '../mock/MockService';
import { SingleCard } from '../model/Inventory';
import { DeckDetailDialog } from '../view/DeckDetailComponent';
import { EditDeckDialog } from '../view/dialog/EditDeckDialog';
import { EditSingleDialog } from '../view/dialog/EditSingleDialog';
import { AddSingleDialog } from '../view/dialog/AddSingleDialog'; 
import { SmartIcon } from '../common/SmartIcon';

@Entry
@Component
struct AdminInventoryPage {
  @State currentTab: number = 0; // 0=Decks, 1=Singles
  @State decks: RentableDeck[] = [];
  @State singles: SingleCard[] = [];
  @State showLowStockOnly: boolean = false;
  
  // Dashboard Stats
  @State totalItems: number = 0;
  @State totalValue: number = 0;
  @State lowStockCount: number = 0;

  // 弹窗控制器
  detailController: CustomDialogController | null = null;
  editDeckController: CustomDialogController | null = null;
  editSingleController: CustomDialogController | null = null;
  addSingleController: CustomDialogController | null = null; 

  async aboutToAppear() {
    this.loadData();
  }
  
  async loadData() {
    this.decks = await MockService.getRentableDecks();
    this.singles = await MockService.getSingles();
    this.calculateStats();
  }
  
  calculateStats() {
    let count = 0;
    let value = 0;
    let low = 0;
    
    // Decks
    this.decks.forEach(d => {
      count++;
      value += (d.deposit || 0);
      if (d.stock < 2) low++;
    });
    
    // Singles
    this.singles.forEach(s => {
      count += s.stock;
      value += (s.price * s.stock);
      if (s.stock < 5) low++;
    });
    
    this.totalItems = count;
    this.totalValue = value;
    this.lowStockCount = low;
  }
  
  getFilteredDecks(): RentableDeck[] {
    if (this.showLowStockOnly) {
      return this.decks.filter(d => d.stock < 2);
    }
    return this.decks;
  }
  
  getFilteredSingles(): SingleCard[] {
    if (this.showLowStockOnly) {
      return this.singles.filter(s => s.stock < 5);
    }
    return this.singles;
  }

  // --- Decks Operations ---
  openDeckDetail(deck: RentableDeck) {
    this.detailController = new CustomDialogController({
      builder: DeckDetailDialog({ deck: deck, controller: undefined }),
      autoCancel: true
    });
    this.detailController.open();
  }

  openEditDeck(deck: RentableDeck | null) {
    this.editDeckController = new CustomDialogController({
      builder: EditDeckDialog({
        targetDeck: deck,
        controller: undefined,
        confirmAction: async (name, fee, deposit, stock, tags, composition, cover) => {
          if (deck) {
            // Update
            await DBHelper.update('decks', { 
              name: name, 
              rentalFeePerHour: fee,
              deposit: deposit, 
              stock: stock,
              tags: JSON.stringify(tags),
              composition: composition,
              cover_image: cover
            }, deck.id);
          } else {
            // Create
            const newId = `d_${new Date().getTime()}`;
            await DBHelper.insert('decks', {
              id: newId,
              name: name,
              rentalFeePerHour: fee,
              deposit: deposit,
              stock: stock,
              tags: JSON.stringify(tags),
              composition: composition,
              cover_image: cover,
              gameType: 'YGO', // Default
              description: '新创建的卡组'
            });
          }
          this.loadData();
        }
      }),
      autoCancel: true
    });
    this.editDeckController.open();
  }

  async quickAddDeckStock(deck: RentableDeck) {
    await DBHelper.update('decks', { stock: deck.stock + 1 }, deck.id);
    this.loadData();
  }

  // --- Singles Operations ---
  openAddSingle() {
    this.addSingleController = new CustomDialogController({
      builder: AddSingleDialog({
        controller: undefined,
        onConfirm: async () => {
          this.loadData();
        }
      }),
      autoCancel: true
    });
    this.addSingleController.open();
  }

  openEditSingle(card: SingleCard) {
    this.editSingleController = new CustomDialogController({
      builder: EditSingleDialog({
        targetCard: card,
        controller: undefined,
        confirmAction: async (name, price, stock, isProxy) => {
          await DBHelper.update('singles', { 
            name: name, price: price, stock: stock, is_proxy: isProxy ? 1 : 0 
          }, card.id);
          this.loadData();
        }
      }),
      autoCancel: true
    });
    this.editSingleController.open();
  }

  async updateSingleStock(card: SingleCard, change: number) {
    const newStock = card.stock + change;
    if (newStock < 0) return;
    await DBHelper.update('singles', { stock: newStock }, card.id);
    this.loadData();
  }

  // UI Builders
  @Builder TabButton(text: string, index: number) {
    Column() {
      Text(text)
        .fontSize(14) 
        .fontColor(this.currentTab === index ? '#007DFF' : '#999')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
      Divider()
        .color(this.currentTab === index ? '#007DFF' : 'transparent')
        .strokeWidth(3)
        .width(30)
        .margin({ top: 5 })
    }
    .width('30%') 
    .onClick(() => this.currentTab = index)
  }

  @Builder StatCard(label: string, value: string, color: string) {
    Column() {
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor(color)
      Text(label).fontSize(10).fontColor('#999').margin({top: 4})
    }
    .width('30%')
    .padding(10)
    .backgroundColor('#FFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.mtga_icon')).width(24).height(24).onClick(() => router.back())
        Text('库存监控').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })
      }
      .width('100%').padding(15).backgroundColor('#FFF')
      
      // Dashboard
      Row() {
        this.StatCard('总库存数', this.totalItems.toString(), '#007DFF')
        this.StatCard('资产估值', `￥${this.totalValue}`, '#28C76F')
        this.StatCard('低库存警报', this.lowStockCount.toString(), '#D94841')
      }
      .width('100%').padding({ left: 10, right: 10, top: 10 }).justifyContent(FlexAlign.SpaceBetween)

      // Tabs & Filter
      Row() {
        Row() {
          this.TabButton('成品卡组', 0)
          this.TabButton('单卡库存', 1)
        }
        .layoutWeight(1)
        
        Row() {
          Checkbox().select(this.showLowStockOnly).onChange((val) => this.showLowStockOnly = val)
          Text('仅显示低库存').fontSize(12).fontColor('#666')
        }
      }
      .width('100%').padding({ top: 10, bottom: 5, right: 15 })

      if (this.currentTab === 0) {
        // --- Decks List ---
        Column() {
          // Add Button
          Button('+ 新建成品卡组')
            .width('100%')
            .height(40)
            .backgroundColor('#E3F2FD')
            .fontColor('#1565C0')
            .margin({ bottom: 10 })
            .onClick(() => this.openEditDeck(null))

          List({ space: 10 }) {
            ForEach(this.getFilteredDecks(), (d: RentableDeck) => {
              ListItem() {
                Column() {
                  Row() {
                    if (d.coverImage && d.coverImage !== 'app.media.mtga_icon') {
                       Image(d.coverImage).width(40).height(40).borderRadius(4).margin({right: 10})
                    } else {
                       SmartIcon({ name: d.name, iconSize: 40 }).margin({right: 10})
                    }
                    
                    Column() {
                      Text(d.name).fontWeight(FontWeight.Bold).maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
                      Text(`库存: ${d.stock} | 租金: ￥${d.rentalFeePerHour}/h | 押金: ￥${d.deposit || 0}`)
                        .fontSize(12).fontColor(d.stock < 2 ? '#D94841' : '#28C76F').margin({ top: 4 })
                      
                      Row() {
                        ForEach(d.tags || [], (tag: string) => {
                          Text(tag).fontSize(10).fontColor('#007DFF').backgroundColor('#E3F2FD').padding(2).borderRadius(2).margin({right: 4})
                        })
                      }.margin({top: 4})
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    
                    Button('+').width(30).height(30).backgroundColor('#E0F2F1').fontColor('#00695C').onClick(() => this.quickAddDeckStock(d))
                  }
                  .width('100%')

                  Divider().color('#EEE').margin({ top: 10, bottom: 10 })
                  
                  Row() {
                    Button('详情').height(24).fontSize(10).backgroundColor('#F5F5F5').fontColor('#666')
                      .onClick(() => this.openDeckDetail(d))
                    Blank()
                    Button('编辑').height(24).fontSize(10).backgroundColor('#E3F2FD').fontColor('#1565C0')
                      .onClick(() => this.openEditDeck(d))
                  }.width('100%')
                }
                .width('100%').padding(15).backgroundColor('#FFF').borderRadius(8)
              }
            })
          }
          .layoutWeight(1)
        }
        .padding(10).layoutWeight(1)
      } else {
        // --- Singles List ---
        Column() {
          // Add Button
          Button('+ 新增单卡库存')
            .width('100%')
            .height(40)
            .backgroundColor('#E3F2FD')
            .fontColor('#1565C0')
            .margin({ bottom: 10 })
            .onClick(() => this.openAddSingle())

          List({ space: 10 }) {
            ForEach(this.getFilteredSingles(), (s: SingleCard) => {
              ListItem() {
                Row() {
                  // Info Area
                  Column() {
                    Row() {
                      if (s.is_proxy) {
                        Text('代牌')
                          .fontSize(10).fontColor('#FFF').backgroundColor('#9E9E9E')
                          .padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(3)
                          .margin({ right: 5 })
                      }
                      Text(s.name).fontWeight(FontWeight.Bold).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    
                    Text(`${s.card_code} | ${s.rarity} | ￥${s.price}`)
                      .fontSize(12).fontColor('#666').margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .onClick(() => this.openEditSingle(s)) 
                  
                  // Stock Control Area
                  Row() {
                    Button('-')
                      .width(32).height(32)
                      .backgroundColor('#FFEBEE') 
                      .fontColor('#D32F2F') 
                      .borderRadius(16)
                      .onClick(() => this.updateSingleStock(s, -1))
                    
                    Text(`${s.stock}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .margin({ left: 12, right: 12 })
                      .fontColor(s.stock < 5 ? '#D94841' : '#333') 
                    
                    Button('+')
                      .width(32).height(32)
                      .backgroundColor('#E8F5E9') 
                      .fontColor('#388E3C') 
                      .borderRadius(16)
                      .onClick(() => this.updateSingleStock(s, 1))
                  }
                }
                .width('100%').padding(15).backgroundColor('#FFF').borderRadius(8)
              }
            })
          }
          .layoutWeight(1) // Ensure list scrolls
        }
        .padding(10).layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}