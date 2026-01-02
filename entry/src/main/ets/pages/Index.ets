import router from '@ohos.router';
import { HomeView } from '../view/HomeView';
import { BookingView } from '../view/BookingView';
import { WikiView } from '../view/WikiView';
import { CommunityView } from '../view/CommunityView'; // [Updated]
import { ProfileView } from '../view/ProfileView';
import { AdminDashboardView } from '../view/AdminDashboardView';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  // 监听全局角色状态
  @StorageLink('userRole') userRole: string | null = null;
  
  private controller: TabsController = new TabsController();

  aboutToAppear() {
    // 简单路由守卫
    if (!this.userRole) {
      router.replaceUrl({ url: 'pages/LoginPage' });
    }
  }

  @Builder TabBuilder(title: string, index: number, iconStr: string) {
    Column() {
      Text(iconStr)
        .fontSize(24)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
        .margin({ bottom: 4 })
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .onClick(() => {
      this.currentIndex = index;
      this.controller.changeIndex(index);
    })
  }

  build() {
    Column() {
      if (!this.userRole) {
        // 未登录占位 (aboutToAppear 会跳转)
        Blank()
      } else if (this.userRole === 'MANAGER' || this.userRole === 'STAFF') {
        // --- 管理员/员工 视图 ---
        AdminDashboardView()
      } else {
        // --- 玩家视图 (Tabs) ---
        Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
          // 1. 赛事大厅
          TabContent() {
            HomeView()
          }
          .tabBar(this.TabBuilder('大厅', 0, '🏠'))

          // 2. 资源预约
          TabContent() {
            BookingView()
          }
          .tabBar(this.TabBuilder('预约', 1, '📅'))

          // 3. 卡牌百科
          TabContent() {
            WikiView()
          }
          .tabBar(this.TabBuilder('百科', 2, '🔍'))

          // 4. 社区
          TabContent() {
            CommunityView() // [Updated]
          }
          .tabBar(this.TabBuilder('社区', 3, '💬'))

          // 5. 个人中心
          TabContent() {
            ProfileView()
          }
          .tabBar(this.TabBuilder('我的', 4, '👤'))
        }
        .scrollable(false)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .backgroundColor('#F1F3F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}