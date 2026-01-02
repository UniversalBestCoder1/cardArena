import router from '@ohos.router';
import { MockService } from '../mock/MockService';
import { Card, GameType } from '../model/Card';

@Component
export struct WikiView {
  @State searchKeyword: string = '';
  @State cardList: Card[] = []; // Filtered list for display
  @State rawResults: Card[] = []; // [New] Cache for unfiltered API results
  @State isLoading: boolean = false;
  @State selectedGame: GameType = GameType.YGO; 
  @State selectedFilter: string = '全部';

  aboutToAppear() {
    this.loadRecommended();
  }

  // 加载本地推荐数据
  async loadRecommended() {
    this.isLoading = true;
    const defaultKeyword = this.selectedGame === GameType.YGO ? 'Blue-Eyes' : 'Lotus';
    this.rawResults = await MockService.searchCards(defaultKeyword, this.selectedGame);
    this.applyFilter(); 
    this.isLoading = false;
  }

  // 执行全网真实搜索 (API)
  async doRealSearch() {
    if (!this.searchKeyword.trim()) return;
    
    this.isLoading = true;
    // Reset filter to All on new search? Optional. Let's keep current filter.
    // this.selectedFilter = 'All'; 
    
    this.rawResults = await MockService.searchCards(this.searchKeyword, this.selectedGame);
    this.applyFilter();
    this.isLoading = false;

    if (this.rawResults.length === 0) {
       // ...
    }
  }
  
  applyFilter() {
    console.info(`[WikiView] Applying filter: ${this.selectedFilter}, raw count: ${this.rawResults ? this.rawResults.length : 'null'}`);
    
    if (!this.rawResults) {
      this.cardList = [];
      return;
    }

    try {
      if (this.selectedFilter === 'All' || this.selectedFilter === '全部') {
        this.cardList = [...this.rawResults]; 
      } else {
        this.cardList = this.rawResults.filter(c => {
           const typeStr = String(c.type || '');
           
           // Bilingual mapping
           let keyword = this.selectedFilter;
           if (this.selectedFilter === '怪兽') return typeStr.includes('怪兽') || typeStr.includes('Monster');
           if (this.selectedFilter === '魔法') return typeStr.includes('魔法') || typeStr.includes('Spell');
           if (this.selectedFilter === '陷阱') return typeStr.includes('陷阱') || typeStr.includes('Trap');
           
           return typeStr.includes(this.selectedFilter);
        });
      }
      console.info(`[WikiView] Filtered count: ${this.cardList.length}`);
    } catch (e) {
      console.error(`[WikiView] Filter error: ${JSON.stringify(e)}`);
      this.cardList = [];
    }
  }

  // 跳转到详情页 (传递 Card 对象)
  navToDetail(card: Card) {
    router.pushUrl({
      url: 'pages/CardDetailPage',
      params: {
        card: card // 直接传递对象
      }
    });
  }

  build() {
    Column() {
      // 1. 顶部游戏切换 (Segmented Control)
      Row() {
        this.GameSwitchBtn('游戏王 (YGO)', GameType.YGO)
        this.GameSwitchBtn('万智牌 (MTG)', GameType.MTG)
      }
      .width('90%')
      .height(36)
      .backgroundColor('#E0E0E0')
      .borderRadius(18)
      .margin({ top: 10, bottom: 4 })
      .padding(2)

      // 2. 搜索栏 (API搜)
      Row() {
        Search({ placeholder: `请输入${this.selectedGame === GameType.YGO ? '游戏王' : '万智牌'}卡名...`, value: this.searchKeyword })
          .searchButton('搜索')
          .width('100%')
          .height(40)
          .backgroundColor('#FFFFFF')
          .placeholderColor('#999')
          .placeholderFont({ size: 14 })
          .onSubmit((value: string) => {
            this.searchKeyword = value;
            this.doRealSearch();
          })
      }
      .padding(10)
      .backgroundColor('#F1F3F5')
      
      // [New] Filter Chips
      List({ space: 10 }) {
        ForEach(this.getFilters(), (filter: string) => {
          ListItem() {
            Text(filter)
              .fontSize(12)
              .fontColor(this.selectedFilter === filter ? '#FFF' : '#666')
              .backgroundColor(this.selectedFilter === filter ? '#007DFF' : '#FFF')
              .padding({left: 12, right: 12, top: 6, bottom: 6})
              .borderRadius(15)
              .onClick(() => {
                this.selectedFilter = filter;
                this.applyFilter(); // [Updated] Instant local filter
              })
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(40)
      .padding({left: 10, right: 10})
      .margin({bottom: 5})

      // 3. 提示栏
      Row() {
        Text('📡 数据来源: YGOPRODeck / Scryfall')
          .fontSize(10)
          .fontColor('#999')
        Blank()
        Text('原生渲染视图')
          .fontSize(10)
          .fontColor('#007DFF')
          .backgroundColor('#E6F2FF')
          .padding(4)
          .borderRadius(4)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 4. 内容区域
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(50).height(50).color('#007DFF')
          Text('正在连接海外 API...').fontSize(14).fontColor('#999').margin({ top: 10 })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.cardList, (item: Card) => {
            ListItem() {
              this.CardItemBuilder(item)
            }
            .onClick(() => {
              this.navToDetail(item);
            })
          }, (item: Card) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 10, right: 10, bottom: 10 })
      }
    }
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  getFilters(): string[] {
    if (this.selectedGame === GameType.YGO) {
      // API returns Chinese types (e.g. "通常怪兽", "魔法卡")
      return ['全部', '怪兽', '魔法', '陷阱', '同调', '超量', '连接'];
    } else {
      return ['All', 'Creature', 'Instant', 'Sorcery', 'Enchantment', 'Artifact', 'Land', 'Planeswalker'];
    }
  }

  @Builder GameSwitchBtn(text: string, type: GameType) {
    Button(text)
      .type(ButtonType.Normal)
      .backgroundColor(this.selectedGame === type ? '#FFFFFF' : 'transparent')
      .fontColor(this.selectedGame === type ? '#000000' : '#999999')
      .fontWeight(this.selectedGame === type ? FontWeight.Bold : FontWeight.Normal)
      .borderRadius(16)
      .layoutWeight(1)
      .height('100%')
      .onClick(() => {
        this.selectedGame = type;
        // [Fix] Reset filter when switching game
        this.selectedFilter = type === GameType.YGO ? '全部' : 'All';
        this.loadRecommended(); 
      })
  }

  @Builder CardItemBuilder(card: Card) {
    Row() {
      // 左侧：卡图 (支持网络图片)
      Image(card.imageUrl.startsWith('http') ? card.imageUrl : $r(card.imageUrl)) 
        .alt($r('app.media.mtga_icon')) // 加载失败/占位图
        .width(80)
        .height(116)
        .borderRadius(4)
        .objectFit(ImageFit.Contain) // 保持比例
        .backgroundColor('#DDD')

      // 右侧：信息
      Column() {
        Row() {
          Text(card.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          
          Text(card.gameType.includes('YGO') ? 'YGO' : 'MTG')
            .fontSize(10)
            .fontColor('#FFF')
            .backgroundColor(card.gameType.includes('YGO') ? '#BE5A00' : '#007DFF') 
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(4)
        }
        .width('100%')

        Text(`${card.type} / ${card.rarity}`)
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 4 })

        Text(card.description)
          .fontSize(12)
          .fontColor('#999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .lineHeight(16)

        Blank()

        Row() {
          Text('参考价:') // 改为通用描述，避免误导
            .fontSize(10)
            .fontColor('#999')
          Text(`￥${card.priceAvg.toFixed(1)}`)
            .fontSize(16)
            .fontColor('#FF0033')
            .fontWeight(FontWeight.Bold)
            .margin({ left: 4 })
          
          Blank()
          
          Text('查看详情 >')
            .fontSize(10)
            .fontColor('#007DFF')
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      }
      .layoutWeight(1)
      .height(116)
      .padding({ left: 10, top: 4, bottom: 4 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(136)
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
  }
}




