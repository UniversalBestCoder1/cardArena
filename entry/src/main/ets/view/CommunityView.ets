import { MockService } from '../mock/MockService';
import { DeckPost } from '../model/SocialDeck';
import { TradeListing, TradeType } from '../model/Trade';
import { SmartIcon } from '../common/SmartIcon';
import promptAction from '@ohos.promptAction';
import { ChatView } from './ChatView';
import { User } from '../model/User';
import { CreateTradeDialog } from '../view/dialog/CreateTradeDialog'; // [New]

@Component
export struct CommunityView {
  @State posts: DeckPost[] = [];
  @State trades: TradeListing[] = [];
  @State currentTab: number = 0; // 0: Deck Hub, 1: Trade, 2: Lobby
  
  // [New] State to pass to ChatView
  @State targetChatUser: User | null = null;
  
  createTradeController: CustomDialogController | null = null;

  async aboutToAppear() {
    this.loadPosts();
    this.loadTrades();
  }

  async loadPosts() {
    this.posts = await MockService.getDeckPosts();
  }
  
  async loadTrades() {
    this.trades = await MockService.getTradeListings();
  }
  
  openCreateTrade() {
    this.createTradeController = new CustomDialogController({
      builder: CreateTradeDialog({
        controller: undefined,
        onConfirm: async () => {
           await this.loadTrades();
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.createTradeController.open();
  }

  // [New] Helper to jump to chat
  startChatWith(userId: string, username: string) {
     // Simplified user object for chat target
     this.targetChatUser = { id: userId, username: username, role: 'PLAYER' }; 
     this.currentTab = 2; // Switch to Lobby/Chat tab
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('社区 Community').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        if (this.currentTab === 1) {
           Button('+ 发布交易').height(28).fontSize(12).onClick(() => this.openCreateTrade())
        }
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#FFF')

      // Tabs (Simplified)
      Row() {
        Button('热门卡组').onClick(() => this.currentTab = 0)
          .backgroundColor(this.currentTab === 0 ? '#007DFF' : '#EEE')
          .fontColor(this.currentTab === 0 ? '#FFF' : '#333')
          .height(30).fontSize(12).margin({right: 10})
        Button('交易布告').onClick(() => this.currentTab = 1)
          .backgroundColor(this.currentTab === 1 ? '#007DFF' : '#EEE')
          .fontColor(this.currentTab === 1 ? '#FFF' : '#333')
          .height(30).fontSize(12).margin({right: 10})
        Button('聊天大厅').onClick(() => this.currentTab = 2) // [New]
          .backgroundColor(this.currentTab === 2 ? '#007DFF' : '#EEE')
          .fontColor(this.currentTab === 2 ? '#FFF' : '#333')
          .height(30).fontSize(12)
      }
      .width('100%').padding({left: 15, bottom: 10}).backgroundColor('#FFF')

      if (this.currentTab === 0) {
        List({ space: 10 }) {
          ForEach(this.posts, (post: DeckPost) => {
            ListItem() {
              Column() {
                Row() {
                  SmartIcon({ name: post.username || 'User', iconSize: 30 })
                  Column() {
                    Text(post.title).fontWeight(FontWeight.Bold).fontSize(16)
                    Text(`by ${post.username}`).fontSize(12).fontColor('#666')
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({left: 10})
                  
                  Text('♥ ' + post.likes).fontSize(12).fontColor('#D94841')
                }.width('100%').margin({bottom: 8})
                
                Text(post.description).fontSize(14).maxLines(2).textOverflow({overflow: TextOverflow.Ellipsis})
                  .margin({bottom: 10})
                
                // Deck Preview (Mini)
                Row() {
                   ForEach(post.deck.cards.main.slice(0, 3), (cardName: string) => {
                      Text(cardName).fontSize(10).backgroundColor('#EEE').padding(4).borderRadius(4).margin({right: 4})
                   })
                   if (post.deck.cards.main.length > 3) Text('...').fontSize(10).fontColor('#999')
                }
                
                Divider().color('#EEE').margin({top: 10, bottom: 5})
                
                Row() {
                  Button('点赞').fontSize(10).backgroundColor('transparent').fontColor('#666')
                    .onClick(() => promptAction.showToast({message: '已点赞'}))
                  Button('复制卡组').fontSize(10).backgroundColor('transparent').fontColor('#007DFF')
                    .onClick(() => {
                       // Logic to copy deck to MyDeck
                       promptAction.showToast({message: '卡组已复制到"我的卡组"'})
                    })
                }
              }
              .padding(15)
              .backgroundColor('#FFF')
              .borderRadius(12)
              .shadow({radius: 4, color: '#1A000000', offsetY: 2})
            }
          }, (p: DeckPost) => p.id)
        }.layoutWeight(1).padding(15)
      } else if (this.currentTab === 1) {
        // --- Trade Board UI ---
        if (this.trades.length === 0) {
           Column() {
             Text('暂无交易信息').fontSize(16).fontColor('#999').margin({top: 50, bottom: 10})
             Text('发布第一条交易需求，让大家看到！').fontSize(12).fontColor('#CCC').margin({bottom: 20})
             Button('+ 发布交易')
               .onClick(() => this.openCreateTrade())
               .backgroundColor('#007DFF')
           }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
        } else {
           List({ space: 10 }) {
             ForEach(this.trades, (t: TradeListing) => {
               ListItem() {
                 Row() {
                   // Type Tag
                   Column() {
                     Text(t.type === TradeType.WANT ? '求' : '出')
                       .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFF')
                   }
                   .width(30).height(30).borderRadius(15)
                   .backgroundColor(t.type === TradeType.WANT ? '#FF9F43' : '#28C76F')
                   .justifyContent(FlexAlign.Center)
                   .margin({right: 10})

                   Column() {
                     Text(`${t.gameType} - ${t.cardName}`)
                       .fontSize(16).fontWeight(FontWeight.Bold)
                     Text(`@${t.username} | ￥${t.price}`)
                       .fontSize(12).fontColor('#666')
                   }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                   Button('私聊')
                     .height(24).fontSize(10).backgroundColor('#007DFF')
                     .onClick(() => this.startChatWith(t.userId, t.username || 'Trader'))
                 }
                 .width('100%').padding(15).backgroundColor('#FFF').borderRadius(8)
                 .shadow({radius: 2, color: '#1A000000', offsetY: 1})
               }
             }, (t: TradeListing) => t.id)
           }.layoutWeight(1).padding(15)
        }
      } else {
        // --- Lobby (ChatView) ---
        Column() {
          ChatView({ targetUser: this.targetChatUser })
        }.layoutWeight(1).width('100%')
      }
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}
