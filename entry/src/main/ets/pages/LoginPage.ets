import router from '@ohos.router';
import { AuthService } from '../service/AuthService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isRegister: boolean = false;
  @State selectedRole: string = 'PLAYER'; // For registration

  async handleLogin() {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请输入用户名和密码' });
      return;
    }
    
    const user = await AuthService.login(this.username, this.password);
    if (user) {
      promptAction.showToast({ message: `欢迎回来, ${user.username}!` });
      // 跳转回 Index
      router.replaceUrl({ url: 'pages/Index' });
    } else {
      promptAction.showToast({ message: '登录失败：用户名或密码错误' });
    }
  }

  async handleRegister() {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请输入用户名和密码' });
      return;
    }

    const success = await AuthService.register(this.username, this.password, this.selectedRole);
    if (success) {
      promptAction.showToast({ message: '注册成功！请登录。' });
      this.isRegister = false;
    } else {
      promptAction.showToast({ message: '注册失败：用户名已存在' });
    }
  }
// ... (rest of build)

  build() {
    Column() {
      // Logo
      Image($r('app.media.mtga_icon'))
        .width(80).height(80)
        .margin({ top: 100, bottom: 20 })
      
      Text('Card Arena')
        .fontSize(24).fontWeight(FontWeight.Bold).margin({ bottom: 50 })

      // Form
      Column({ space: 15 }) {
        TextInput({ placeholder: '用户名', text: this.username })
          .onChange((val) => this.username = val)
          .backgroundColor('#FFF')
        
        TextInput({ placeholder: '密码', text: this.password })
          .type(InputType.Password)
          .onChange((val) => this.password = val)
          .backgroundColor('#FFF')

        if (this.isRegister) {
          Row() {
            Text('角色: ').margin({ right: 10 })
            Select([{ value: 'PLAYER' }, { value: 'STAFF' }, { value: 'MANAGER' }])
              .selected(0)
              .value(this.selectedRole)
              .onSelect((index, value) => this.selectedRole = value)
          }.width('100%').justifyContent(FlexAlign.Start)
        }

        Button(this.isRegister ? '注 册' : '登 录')
          .width('100%')
          .height(45)
          .margin({ top: 20 })
          .onClick(() => {
            if (this.isRegister) this.handleRegister();
            else this.handleLogin();
          })
        
        Text(this.isRegister ? '已有账号？去登录' : '没有账号？去注册')
          .fontSize(14).fontColor('#007DFF')
          .margin({ top: 10 })
          .onClick(() => this.isRegister = !this.isRegister)
      }
      .width('80%')
    }
    .width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}