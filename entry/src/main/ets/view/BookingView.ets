import { InventoryService } from '../service/InventoryService';
import { BookingService } from '../service/BookingService';
import { TournamentService } from '../service/TournamentService';
import { Seat } from '../model/Seat';
import { User } from '../model/User';
import { RentableDeck } from '../model/RentableDeck';
import { Tournament, TournamentStatus, OrganizerType, YGOFormat, MTGFormat } from '../model/Tournament';
import { GameType } from '../model/Card';
import { SmartIcon } from '../common/SmartIcon';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import { DeckDetailDialog } from './DeckDetailComponent';
import { RefereeDetailDialog } from './dialog/RefereeDetailDialog'; // [New]

@Component
export struct BookingView {
  @State currentTab: number = 0; // 0: 租卡组, 1: 订桌位, 2: 办比赛
  @State deckList: RentableDeck[] = [];
  
  // 座位状态
  @State seats: Seat[] = [];
  @State selectedSeatId: string = '';

  // 办比赛表单状态
  @State newTournamentTitle: string = '';
  @State newTournamentGame: GameType = GameType.YGO;
  @State newTournamentFormat: string = 'OCG Advanced'; // 默认
  @State newTournamentTime: string = '2025-12-30 18:00';
  @State newTournamentPlayers: number = 8;
  @State newTournamentFee: number = 0;
  @State newTournamentDesc: string = '';
  @State newTournamentPoster: string = ''; // [New]
  @State newTournamentReferee: boolean = false;
  
  // [New] Referee State
  @State refereeList: User[] = [];
  @State selectedRefereeId: string = '';
  @State selectedReferee: User | null = null;
  refereeController: CustomDialogController | null = null;

  // 弹窗控制器
  detailController: CustomDialogController | null = null;
  @State selectedDeck: RentableDeck | null = null;

  async aboutToAppear() {
    this.loadDecks();
    this.loadSeats();
    this.loadReferees();
  }
  
  async loadReferees() {
    this.refereeList = await BookingService.getAvailableReferees();
  }

  async loadDecks() {
    this.deckList = await InventoryService.getRentableDecks();
  }

  async loadSeats() {
    this.seats = await BookingService.getSeats();
    this.selectedSeatId = ''; // 重置选择
  }
  
  async selectPoster() {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      
      const photoViewPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      
      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        this.newTournamentPoster = photoSelectResult.photoUris[0];
        console.info('Selected poster URI:', this.newTournamentPoster);
      }
    } catch (err) {
      console.error('PhotoViewPicker failed with err: ' + JSON.stringify(err));
    }
  }

  // 打开详情弹窗
  openDetail(deck: RentableDeck) {
    this.selectedDeck = deck;
    this.detailController = new CustomDialogController({
      builder: DeckDetailDialog({
        deck: this.selectedDeck,
        controller: undefined // 内部会自动注入
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.detailController.open();
  }

  async handleRent(deck: RentableDeck) {
    // 弹窗确认押金
    AlertDialog.show({
      title: '确认租借',
      message: `租借此卡组需要支付押金 ${deck.deposit} 积分。\n(归还时将自动退还)\n确定继续吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '支付押金并租借',
        fontColor: '#007DFF',
        action: async () => {
          const success = await InventoryService.rentDeck(deck.id);
          if (success) {
            this.loadDecks();
            AlertDialog.show({ message: `租借成功！\n押金已扣除 ${deck.deposit} 积分。` });
          } else {
            AlertDialog.show({ message: '租借失败：余额不足或库存不足。' });
          }
        }
      }
    });
  }

  async handleReturn(deck: RentableDeck) {
    // 记录归还前余额
    // 注意：这里需要 AuthService，但为简化直接用 InventoryService 包装或者保持简单
    // 这里的逻辑稍微复杂，因为我们要显示余额变化。
    // 最好在 InventoryService 中增加 getUserBalance 代理或者 import AuthService
    // 暂时我们不显示余额变化，或者引入 AuthService。
    // 让我们引入 AuthService 吧。
    
    // 暂时保留原逻辑，仅替换核心调用
    const success = await InventoryService.returnDeck(deck.id);
    if (success) {
      this.loadDecks();
      AlertDialog.show({
        title: '归还结算',
        message: `归还成功！\n\n已退还押金并扣除租金。` 
      });
    }
  }

  async handleBookSeat() {
    if (!this.selectedSeatId) {
      promptAction.showToast({ message: '请先选择一个座位' });
      return;
    }

    const success = await BookingService.bookSeat(this.selectedSeatId);
    if (success) {
      AlertDialog.show({ message: `预订成功！\n座位号：${this.selectedSeatId}\n请按时入座。` });
      this.loadSeats(); // 刷新状态
    } else {
      AlertDialog.show({ message: '预订失败：该座位已被抢占。' });
      this.loadSeats();
    }
  }

  async submitTournament() {
    console.info('[BookingView] submitTournament clicked');
    if (!this.newTournamentTitle) {
      console.info('[BookingView] Title is empty');
      promptAction.showToast({ message: '请输入比赛标题' });
      return;
    }

    const t: Tournament = {
      id: `p_evt_${new Date().getTime()}`,
      title: this.newTournamentTitle,
      gameType: this.newTournamentGame,
      format: this.newTournamentFormat,
      startTime: this.newTournamentTime,
      status: TournamentStatus.REGISTERING,
      maxPlayers: this.newTournamentPlayers,
      currentPlayers: 0,
      entryFee: this.newTournamentFee,
      location: '玩家预约区',
      description: this.newTournamentDesc || '玩家自办赛事',
      organizerType: OrganizerType.PLAYER,
      organizerName: '我 (当前用户)',
      organizerId: 'current_user', // Will be overridden by service/mock using actual current user
      poster: this.newTournamentPoster, // [New]
      requireReferee: this.newTournamentReferee,
      refereeId: this.newTournamentReferee ? this.selectedRefereeId : undefined,
      allowedDecks: '无限制'
    };

    // [Fix] Manually set organizerId from service/auth if possible, but MockService creates it based on current user context mostly. 
    // Actually, MockService.createTournament uses the passed object. We should get current user here.
    const user = await import('../mock/MockService').then(m => m.MockService.getCurrentUser());
    if (user) {
       t.organizerId = user.id;
       t.organizerName = user.username;
    }
    
    // Default poster handling moved to service, but if user inputs something, use it.
    
    console.info('[BookingView] Submitting tournament:', JSON.stringify(t));

    try {
      const success = await TournamentService.createTournament(t);
      console.info('[BookingView] Create result:', success);
      
      if (success) {
        AlertDialog.show({
          title: '提交成功',
          message: '赛事申请已提交！\n请等待店长审核通过后上线。',
          confirm: {
            value: '确定',
            action: () => {}
          }
        });
        // Reset form
        this.newTournamentTitle = '';
        this.newTournamentDesc = '';
        this.newTournamentPoster = '';
        this.newTournamentReferee = false;
        this.selectedRefereeId = '';
      } else {
        AlertDialog.show({ title: '提交失败', message: '未知错误，请重试。' });
      }
    } catch (e) {
      console.error('[BookingView] Submit error:', JSON.stringify(e));
      AlertDialog.show({
        title: '提交出错',
        message: `发生错误: ${JSON.stringify(e)}` 
      });
    }
  }

  build() {
    Column() {
      // 顶部切换栏
      Row() {
        this.SegmentButton('租借卡组', 0)
        this.SegmentButton('预订桌位', 1)
        this.SegmentButton('举办比赛', 2)
      }
      .width('95%')
      .height(40)
      .backgroundColor('#E0E0E0')
      .borderRadius(20)
      .margin({ top: 10, bottom: 10 })
      .padding(4)

      if (this.currentTab === 0) {
        // --- 租卡组视图 ---
        List({ space: 12 }) {
          ForEach(this.deckList, (item: RentableDeck) => {
            ListItem() {
              this.DeckCard(item)
            }
          }, (item: RentableDeck) => `${item.id}_${item.stock}_${item.isRentedByMe}`) // [Fixed] 强制刷新 Key
        }
        .width('100%')
        .layoutWeight(1)
        .padding(16)
      } else if (this.currentTab === 1) {
        // --- 订桌位视图 ---
        Column() {
          Text('可视化选座 (今日)').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10, bottom: 10 })

          // 图例
          Row() {
            this.LegendItem('#EEE', '可选')
            this.LegendItem('#007DFF', '已选')
            this.LegendItem('#D94841', '已占')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 20 })

          // 座位区域 Grid
          Scroll() {
            Column() {
              Text('普通对战区').fontSize(14).fontColor('#666').margin({ bottom: 8 }).width('100%')
              Grid() {
                ForEach(this.seats.filter(s => s.type === 'COMMON'), (seat: Seat) => {
                  GridItem() {
                    this.SeatItem(seat)
                  }
                }, (seat: Seat) => `${seat.id}_${seat.isBooked}`) 
              }
              .columnsTemplate('1fr 1fr 1fr 1fr')
              .rowsGap(10)
              .columnsGap(10)
              .height(120) 

              Divider().color('#EEE').margin({ top: 20, bottom: 20 })

              Text('VIP 包厢区').fontSize(14).fontColor('#FF9500').margin({ bottom: 8 }).width('100%')
              Grid() {
                 ForEach(this.seats.filter(s => s.type === 'VIP'), (seat: Seat) => {
                  GridItem() {
                    this.SeatItem(seat)
                  }
                }, (seat: Seat) => `${seat.id}_${seat.isBooked}`)
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(20)
              .height(80)
            }
            .width('100%')
            .padding(20)
          }
          .layoutWeight(1)

          // 底部栏
          Column() {
             Text(this.selectedSeatId ? `已选择: ${this.selectedSeatId}` : '请选择座位')
              .fontSize(14)
              .margin({ bottom: 10 })
             
             Button('确认预订')
              .width('90%')
              .height(45)
              .enabled(!!this.selectedSeatId)
              .backgroundColor(this.selectedSeatId ? '#007DFF' : '#CCC')
              .onClick(() => this.handleBookSeat())
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#FFF')
          .shadow({ radius: 10, color: '#1A000000', offsetY: -2 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F1F3F5')
      } else {
        // --- 举办比赛视图 ---
        Scroll() {
          Column({ space: 15 }) {
            Text('申请举办赛事')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            
            // 标题
            TextInput({ placeholder: '赛事标题 (e.g. 周末练习赛)', text: this.newTournamentTitle })
              .onChange((val) => this.newTournamentTitle = val)
              .backgroundColor('#FFF')

            // 游戏类型
            Row() {
              Text('游戏: ').width(60)
              Row() {
                Radio({ value: 'YGO', group: 'gType' }).checked(this.newTournamentGame === GameType.YGO)
                  .onChange((isChecked) => { if(isChecked) this.newTournamentGame = GameType.YGO })
                Text('YGO').margin({ right: 20 })
                
                Radio({ value: 'MTG', group: 'gType' }).checked(this.newTournamentGame === GameType.MTG)
                  .onChange((isChecked) => { if(isChecked) this.newTournamentGame = GameType.MTG })
                Text('MTG')
              }
            }.width('100%')

            // 赛制 (简化为输入框，实际可做下拉)
            TextInput({ placeholder: '赛制 (e.g. Standard, OCG)', text: this.newTournamentFormat })
              .onChange((val) => {
                this.newTournamentFormat = val;
                // [New] Suggest price based on format
                if (val.toLowerCase().includes('standard')) this.newTournamentFee = 50;
                else if (val.toLowerCase().includes('ocg')) this.newTournamentFee = 30;
                else if (val.toLowerCase().includes('commander')) this.newTournamentFee = 10;
                else if (val.toLowerCase().includes('draft')) this.newTournamentFee = 100;
              })
              .backgroundColor('#FFF')

            // 时间
            TextInput({ placeholder: '时间 (e.g. 2025-12-30 18:00)', text: this.newTournamentTime })
              .onChange((val) => this.newTournamentTime = val)
              .backgroundColor('#FFF')

            // 人数 & 费用
            Row() {
              TextInput({ placeholder: '人数上限' })
                .type(InputType.Number)
                .onChange((val) => this.newTournamentPlayers = parseInt(val) || 8)
                .layoutWeight(1)
                .backgroundColor('#FFF')
                .margin({ right: 10 })
              
              Column() {
                TextInput({ placeholder: '申请报名费', text: this.newTournamentFee > 0 ? this.newTournamentFee.toString() : '' })
                  .type(InputType.Number)
                  .onChange((val) => this.newTournamentFee = parseInt(val) || 0)
                  .backgroundColor('#FFF')
                  .width('100%')
                Text('建议价格 (待店长审核)').fontSize(10).fontColor('#999').margin({top: 2})
              }.layoutWeight(1)
            }.width('100%').alignItems(VerticalAlign.Top)
            
            // 裁判预约
            Row() {
              Checkbox()
                .select(this.newTournamentReferee)
                .onChange((val) => {
                  this.newTournamentReferee = val;
                  if (!val) {
                    this.selectedRefereeId = '';
                    this.selectedReferee = null;
                  }
                })
              Text('需要预约裁判协助 (需额外支付费用)')
                .fontSize(14)
                .fontColor('#666')
            }.width('100%')

            if (this.newTournamentReferee) {
              Text('选择裁判:')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .margin({top: 10, bottom: 5})
              
              if (this.refereeList.length === 0) {
                 Text('暂无可用裁判').fontSize(12).fontColor('#999')
              }

              List({ space: 10 }) {
                ForEach(this.refereeList, (r: User) => {
                  ListItem() {
                    Row() {
                      SmartIcon({ name: r.username, iconSize: 40 })
                      Column() {
                        Text(r.username).fontSize(16).fontWeight(FontWeight.Bold)
                        Text(`经验: ${r.refereeProfile?.yearsOfExperience || 0}年 | 擅长: ${(r.refereeProfile?.specializedGame || []).join(', ')}`)
                          .fontSize(12).fontColor('#666')
                      }.layoutWeight(1).padding({left: 10}).alignItems(HorizontalAlign.Start)
                      
                      if (this.selectedRefereeId === r.id) {
                         Text('已选').fontColor('#007DFF').fontSize(12)
                      }
                    }
                    .width('100%')
                    .padding(10)
                    .backgroundColor(this.selectedRefereeId === r.id ? '#E6F2FF' : '#FFF')
                    .borderRadius(8)
                    .onClick(() => {
                       this.selectedReferee = r;
                       this.refereeController = new CustomDialogController({
                         builder: RefereeDetailDialog({
                           referee: this.selectedReferee,
                           controller: undefined,
                           onConfirm: () => {
                             this.selectedRefereeId = r.id;
                           }
                         }),
                         autoCancel: true,
                         alignment: DialogAlignment.Center
                       });
                       this.refereeController.open();
                    })
                  }
                })
              }
              .height(this.refereeList.length * 70 + 20)
              .constraintSize({ minHeight: 0, maxHeight: 200 })
            }

            // 描述
            TextArea({ placeholder: '赛事描述 / 规则补充' })
              .height(100)
              .onChange((val) => this.newTournamentDesc = val)
              .backgroundColor('#FFF')

            // [New] 海报设置
            Text('赛事海报 (可选)').fontSize(14).fontWeight(FontWeight.Bold).margin({ top: 10, bottom: 5 })
            Row() {
              if (this.newTournamentPoster) {
                Image(this.newTournamentPoster)
                  .width(100)
                  .height(60)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(4)
                  .margin({ right: 10 })
                  .onClick(() => this.selectPoster())
              }
              
              Button(this.newTournamentPoster ? '更换海报' : '选择海报')
                .fontSize(12)
                .backgroundColor('#EEE')
                .fontColor('#333')
                .onClick(() => this.selectPoster())
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 10 })

            Button('提交申请')
              .width('100%')
              .height(45)
              .margin({ top: 20 })
              .onClick(() => this.submitTournament())
          }
          .padding(20)
        }
        .layoutWeight(1)
        .backgroundColor('#F1F3F5')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder LegendItem(color: string, text: string) {
    Row() {
      Rect().width(12).height(12).fill(color).radius(2)
      Text(text).fontSize(12).margin({ left: 4 })
    }.margin({ left: 10, right: 10 })
  }

  @Builder SeatItem(seat: Seat) {
    Column() {
      Text(seat.label)
        .fontSize(12)
        .fontColor(seat.isBooked ? '#FFF' : (this.selectedSeatId === seat.id ? '#FFF' : '#333'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(seat.type === 'VIP' ? 60 : 40)
    .backgroundColor(
      seat.isBooked ? '#D94841' : 
      (this.selectedSeatId === seat.id ? '#007DFF' : '#EEE')
    )
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (seat.isBooked) {
        promptAction.showToast({ message: '该座位已被预订' });
        return;
      }
      if (this.selectedSeatId === seat.id) {
        this.selectedSeatId = ''; // 取消选择
      } else {
        this.selectedSeatId = seat.id;
      }
    })
  }

  @Builder SegmentButton(text: string, index: number) {
    Button(text)
      .type(ButtonType.Normal)
      .backgroundColor(this.currentTab === index ? '#FFFFFF' : 'transparent')
      .fontColor(this.currentTab === index ? '#000000' : '#999999')
      .borderRadius(16)
      .layoutWeight(1)
      .height('100%')
      .onClick(() => this.currentTab = index)
  }

  @Builder DeckCard(deck: RentableDeck) {
    Row() {
      // 1. 动态图标 (替代丑陋的默认图)
      SmartIcon({ name: deck.name, iconSize: 80 })

      // 2. 信息 (中)
      Column() {
        Text(deck.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Row() {
          ForEach(deck.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor('#007DFF')
              .backgroundColor('#E6F2FF')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .borderRadius(4)
              .margin({ right: 4 })
          })
        }
        .margin({ top: 6 })

        // 查看详情入口
        Text('查看构筑详情 >')
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 8 })
          .onClick(() => this.openDetail(deck)) // 点击打开弹窗
      }
      .layoutWeight(1)
      .padding({ left: 12 })
      .alignItems(HorizontalAlign.Start)

      // 3. 操作 (右)
      Column() {
        Text(`￥${deck.rentalFeePerHour}/h`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF9500')
          .margin({ bottom: 8 })

        if (deck.isRentedByMe) {
          Button('归还')
            .fontSize(12)
            .backgroundColor('#D94841')
            .height(28)
            .onClick(() => this.handleReturn(deck))
        } else {
          Button(deck.stock > 0 ? '租用' : '缺货')
            .fontSize(12)
            .backgroundColor(deck.stock > 0 ? '#007DFF' : '#CCC')
            .enabled(deck.stock > 0)
            .height(28)
            .onClick(() => this.handleRent(deck))
        }
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    // 点击卡片任意位置也可以看详情，除了按钮
    .onClick(() => this.openDetail(deck)) 
  }
}
