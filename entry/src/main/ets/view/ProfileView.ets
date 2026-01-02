import router from '@ohos.router';
import { MockService } from '../mock/MockService';
import { User } from '../model/User';
import relationalStore from '@ohos.data.relationalStore';
import { SmartIcon } from '../common/SmartIcon'; // [New]

@Component
export struct ProfileView {
  @StorageLink('currentUser') user: User | null = null;

  async aboutToAppear() {
    // 确保显示最新余额
    await MockService.getUserBalance();
  }

  build() {
    Column() {
      // 1. 头部用户信息
      Row() {
        SmartIcon({ name: this.user ? this.user.username : 'Guest', iconSize: 60 })
          .margin({ right: 16 })
        
        Column() {
          Text(this.user ? this.user.username : '未登录')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF')
          Text(`Role: ${this.user ? this.user.role : 'Guest'}`)
            .fontSize(12)
            .fontColor('#EEE')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text('会员 >')
          .fontSize(14)
          .fontColor('#FFF')
          .onClick(() => { 
            router.pushUrl({ url: 'pages/MemberCardPage' });
          })
      }
      .width('100%')
      .height(150)
      .padding({ left: 20, right: 20, top: 40 })
      .backgroundColor('#2C3E50')
      
      // 2. 悬浮数据卡片
      Row() {
        ProfileStatItem({ val: '12', label: '参赛次数' })
        ProfileStatItem({ val: '58%', label: '当前胜率' })
        // [Fixed] 绑定真实余额
        ProfileStatItem({ val: (this.user?.wallet_balance || 0).toString(), label: '我的积分' })
      }
      .width('90%')
      .height(80)
      .backgroundColor('#FFF')
      .borderRadius(12)
      .margin({ top: -30 })
      .shadow({ radius: 8, color: '#1A000000', offsetY: 4 })
      .justifyContent(FlexAlign.SpaceEvenly)

      // 3. 菜单列表
      Column() {
        // [Fixed] 绑定真实余额，统一单位为"积分"
        ProfileMenuItem({ 
          title: `我的钱包 (余额: ${this.user?.wallet_balance || 0} 积分)`, 
          action: () => { router.pushUrl({ url: 'pages/WalletPage' }) } 
        })
        ProfileMenuItem({ 
          title: '我的卡本 / 构筑', 
          action: () => { router.pushUrl({ url: 'pages/MyDeckPage' }) } 
        })
        ProfileMenuItem({ 
          title: '租借记录', 
          action: () => { router.pushUrl({ url: 'pages/RentalHistoryPage' }) } 
        })
        ProfileMenuItem({ 
          title: '设置', 
          action: () => { 
            AlertDialog.show({
              title: '系统设置',
              message: '开发调试选项',
              primaryButton: {
                value: '重置数据库',
                fontColor: '#D94841',
                action: async () => {
                  try {
                    // 强制删除数据库文件，下次启动时会重建
                    const ctx = getContext(this);
                    await relationalStore.deleteRdbStore(ctx, 'CardArena_v18.db');
                    AlertDialog.show({ message: '数据已重置，请完全关闭并重启应用。' });
                  } catch (e) {
                    AlertDialog.show({ message: '重置失败: ' + JSON.stringify(e) });
                  }
                }
              },
              secondaryButton: {
                value: '关闭',
                action: () => {}
              }
            });
          } 
        })
        
        Divider().margin({ top: 10, bottom: 10 })
        
        // [Updated] 退出登录
        Button('退出登录')
          .width('100%')
          .backgroundColor('#D94841')
          .margin({ top: 20 })
          .onClick(() => {
            MockService.logout();
            router.replaceUrl({ url: 'pages/LoginPage' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}

@Component
struct ProfileStatItem {
  @Prop val: string;
  @Prop label: string;

  build() {
    Column() {
      Text(this.val)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
      Text(this.label)
        .fontSize(12)
        .fontColor('#999')
        .margin({ top: 4 })
    }
  }
}

@Component
struct ProfileMenuItem {
  @Prop title: string;
  action?: () => void;

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor('#333')
      Blank()
      Text('>')
        .fontSize(14)
        .fontColor('#CCC')
    }
    .width('100%')
    .height(50)
    .backgroundColor('#FFF')
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 1 })
    .onClick(() => {
      if (this.action) this.action();
    })
  }
}