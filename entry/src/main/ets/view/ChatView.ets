import { ChatService } from '../service/ChatService';
import { AuthService } from '../service/AuthService';
import { AiService } from '../service/AiService';
import { ChatMessage } from '../model/Chat';
import { User } from '../model/User';
import { SmartIcon } from '../common/SmartIcon';
import { UserSearchDialog } from './dialog/UserSearchDialog';

@Component
export struct ChatView {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @StorageLink('currentUser') currentUser: User | null = null;
  @State targetUser: User | null = null; // 当前私聊对象
  @State isAiMode: boolean = false; 
  @State viewMode: 'LIST' | 'CHAT' = 'LIST';
  @State friendList: User[] = [];
  @State recentList: User[] = [];
  
  // 滚动控制器
  scroller: Scroller = new Scroller();
  
  // 定时器 ID
  timerId: number = -1;
  
  searchController: CustomDialogController | null = null;

  aboutToAppear(): void {
    // [Fix] Ensure we have the latest user
    import('../mock/MockService').then(m => {
       const u = m.MockService.getCurrentUser();
       if(u) this.currentUser = u;
    });

    if (this.targetUser) {
      this.viewMode = 'CHAT';
      this.loadMessages();
    } else {
      this.loadLists();
    }
    
    // 简单轮询模拟实时聊天 (每2秒刷新一次)
    this.timerId = setInterval(() => {
      if (this.viewMode === 'CHAT' && !this.isAiMode) {
        this.loadMessages();
      }
    }, 2000);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }
  
  async loadLists() {
    import('../mock/MockService').then(async m => {
      this.friendList = await m.MockService.getFriends();
      this.recentList = await m.MockService.getRecentConversations();
    });
  }

  async loadMessages(): Promise<void> {
    if (this.isAiMode) return; 

    const allMsgs = await ChatService.getChatMessages();
    
    // 筛选当前会话的消息
    const filteredMsgs = allMsgs.filter(msg => {
      if (this.targetUser) {
        // 私聊模式
        return (msg.sender_id === this.currentUser?.id && msg.receiver_id === this.targetUser.id) ||
               (msg.sender_id === this.targetUser.id && msg.receiver_id === this.currentUser?.id);
      } else {
        // 公共模式
        return !msg.receiver_id;
      }
    });

    const shouldScroll = filteredMsgs.length > this.messages.length;
    this.messages = filteredMsgs;
    
    if (shouldScroll) {
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 100);
    }
  }

  async handleSend(): Promise<void> {
    if (!this.inputText.trim()) return;
    const content = this.inputText;
    this.inputText = ''; 
    
    // [UI] Optimistic update
    const userMsg: ChatMessage = {
        id: new Date().getTime(),
        sender_id: this.currentUser?.id || 'unknown',
        sender_name: this.currentUser?.username || '我',
        sender_role: 'PLAYER',
        content: content,
        timestamp: new Date().getTime()
    };
    this.messages.push(userMsg);
    this.scroller.scrollEdge(Edge.Bottom);

    if (this.isAiMode) {
      const aiResponse = await AiService.askAI(content);
      const aiMsg: ChatMessage = {
        id: new Date().getTime() + 1,
        sender_id: 'u_ai',
        sender_name: '决斗精灵 (AI)',
        sender_role: 'SYSTEM',
        content: aiResponse,
        timestamp: new Date().getTime() + 1
      };
      this.messages.push(aiMsg);
      this.scroller.scrollEdge(Edge.Bottom);
    } else {
      const receiverId = this.targetUser ? this.targetUser.id : '';
      await ChatService.sendChatMessage(content, receiverId);
      setTimeout(() => this.loadMessages(), 500); 
    }
  }

  startPrivateChat(userId: string, username: string, role: string) {
    if (userId === this.currentUser?.id) return; 
    this.targetUser = { id: userId, username: username, role: role as 'MANAGER' | 'STAFF' | 'PLAYER' };
    this.isAiMode = false;
    this.loadMessages();
  }

  toggleAiMode() {
    this.isAiMode = !this.isAiMode;
    this.targetUser = null;
    this.messages = []; 
    if (this.isAiMode) {
      this.messages.push({
        id: 0,
        sender_id: 'u_ai',
        sender_name: '决斗精灵',
        sender_role: 'SYSTEM',
        content: '你好，决斗者！我是你的智能助手。关于卡组构筑、规则判罚，尽管问我吧！',
        timestamp: new Date().getTime()
      });
    } else {
      this.loadMessages();
    }
  }
  
  enterChat(user: User | null) {
    this.targetUser = user;
    this.viewMode = 'CHAT';
    this.isAiMode = false;
    this.loadMessages();
  }
  
  backToList() {
    this.viewMode = 'LIST';
    this.targetUser = null;
    this.loadLists();
  }
  
  openSearch() {
    this.searchController = new CustomDialogController({
      builder: UserSearchDialog({
        controller: undefined,
        onChat: (u: User) => {
          this.enterChat(u);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.searchController.open();
  }

  build() {
    Column() {
      if (this.viewMode === 'LIST') {
        // --- Inbox / List Mode ---
        Row() {
          Text('消息中心').fontSize(20).fontWeight(FontWeight.Bold)
          Blank()
          Button('🔍').onClick(() => {
             this.openSearch();
          }).backgroundColor('transparent').fontColor('#333')
        }
        .width('100%').padding(15).backgroundColor('#FFF')
        
        List() {
          // 1. Lobby
          ListItem() {
            Row() {
              Stack() {
                Circle().width(50).height(50).fill('#007DFF')
                Text('📢').fontSize(24).fontColor('#FFF')
              }
              .margin({right: 10})
              
              Column() {
                Text('公共聊天大厅').fontSize(16).fontWeight(FontWeight.Bold)
                Text('全服喊话...').fontSize(12).fontColor('#999')
              }.alignItems(HorizontalAlign.Start)
            }
            .width('100%').padding(15).backgroundColor('#FFF')
            .onClick(() => this.enterChat(null))
          }
          
          // 2. AI
          ListItem() {
            Row() {
              Stack() {
                Circle().width(50).height(50).fill('#7367F0')
                Text('🤖').fontSize(24).fontColor('#FFF')
              }
              .margin({right: 10})
              
              Column() {
                Text('决斗精灵 (AI)').fontSize(16).fontWeight(FontWeight.Bold)
                Text('智能规则助手').fontSize(12).fontColor('#999')
              }.alignItems(HorizontalAlign.Start)
            }
            .width('100%').padding(15).backgroundColor('#FFF')
            .onClick(() => {
               this.viewMode = 'CHAT';
               this.isAiMode = true;
               this.targetUser = null;
               this.messages = []; 
               // Add welcome msg...
            })
          }

          // 3. Friends / Recent
          if (this.friendList.length > 0) {
             ListItem() { Text('好友').fontSize(12).fontColor('#999').padding({left: 15, top: 10}) }
             ForEach(this.friendList, (u: User) => {
               ListItem() {
                 this.UserRow(u)
               }
             })
          }
          
          if (this.recentList.length > 0) {
             ListItem() { Text('最近会话').fontSize(12).fontColor('#999').padding({left: 15, top: 10}) }
             ForEach(this.recentList, (u: User) => {
               ListItem() {
                 this.UserRow(u)
               }
             })
          }
        }
        .layoutWeight(1)
        .backgroundColor('#F1F3F5')

      } else {
        // --- Chat Mode (Existing UI) ---
        // Top Bar
        Row() {
          Button('<').onClick(() => this.backToList()).backgroundColor('transparent').fontColor('#333').margin({right: 5})
          
          if (this.isAiMode) {
            Text('🤖 与 决斗精灵 对话中').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#7367F0')
          } else if (this.targetUser) {
            Text(this.targetUser.username).fontSize(16).fontWeight(FontWeight.Bold)
          } else {
            Text('公共大厅').fontSize(16).fontWeight(FontWeight.Bold)
          }
          
          Blank()
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF')
        .border({ width: { bottom: 1 }, color: '#EEE' })

        // Message List
        List({ scroller: this.scroller }) {
          ForEach(this.messages, (msg: ChatMessage) => {
            ListItem() {
              this.MessageItem(msg)
            }
          }, (msg: ChatMessage) => msg.id.toString())
        }
        .layoutWeight(1)
        .width('100%')
        .padding(10)

        // Input
        Row() {
          TextInput({ placeholder: this.isAiMode ? '问问 AI...' : '发送消息...', text: this.inputText })
            .layoutWeight(1)
            .height(40)
            .onChange((val) => this.inputText = val)
            .onSubmit(() => this.handleSend())
          
          Button('发送')
            .height(40)
            .margin({ left: 10 })
            .onClick(() => this.handleSend())
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder UserRow(u: User) {
    Row() {
      SmartIcon({ name: u.username, iconSize: 40 }).margin({right: 10})
      Text(u.username).fontSize(16).fontWeight(FontWeight.Bold)
    }
    .width('100%').padding(15).backgroundColor('#FFF')
    .onClick(() => this.enterChat(u))
  }

  @Builder MessageItem(msg: ChatMessage) {
    Row() {
      if (msg.sender_id === this.currentUser?.id) {
        Blank()
        Column() {
          Text(msg.content)
            .fontSize(14)
            .fontColor('#FFF')
            .backgroundColor('#007DFF')
            .padding(10)
            .borderRadius({ topLeft: 10, topRight: 0, bottomLeft: 10, bottomRight: 10 })
        }
        .alignItems(HorizontalAlign.End)
        .margin({ right: 10 })
        
        SmartIcon({ name: this.currentUser?.username || 'Me', iconSize: 40 })
      } else {
        SmartIcon({ 
          name: msg.sender_name, 
          iconSize: 40,
          colorOverride: msg.sender_id === 'u_ai' ? '#7367F0' : '' 
        })
        .onClick(() => {
             if (msg.sender_id !== 'u_ai') {
               this.startPrivateChat(msg.sender_id, msg.sender_name, msg.sender_role)
             }
        })
        
        Column() {
          Text(`${msg.sender_name} ${msg.sender_role === 'MANAGER' ? '(店长)' : ''}`)
            .fontSize(10).fontColor('#999').margin({ bottom: 2 })
          
          Text(msg.content)
            .fontSize(14)
            .fontColor('#333')
            .backgroundColor('#FFF')
            .padding(10)
            .borderRadius({ topLeft: 0, topRight: 10, bottomLeft: 10, bottomRight: 10 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        Blank()
      }
    }
    .width('100%')
    .margin({ bottom: 15 })
  }
}