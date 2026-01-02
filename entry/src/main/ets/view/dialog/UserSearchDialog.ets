import { MockService } from '../../mock/MockService';
import { User } from '../../model/User';
import { SmartIcon } from '../../common/SmartIcon';
import promptAction from '@ohos.promptAction';

@CustomDialog
export struct UserSearchDialog {
  controller: CustomDialogController;
  onChat: (u: User) => void = () => {};
  
  @State keyword: string = '';
  @State searchResults: User[] = [];

  async handleSearch() {
    if (!this.keyword.trim()) return;
    this.searchResults = await MockService.searchUsers(this.keyword);
  }

  async handleAddFriend(u: User) {
    const success = await MockService.addFriend(u.id);
    if (success) {
      promptAction.showToast({ message: `已添加 ${u.username} 为好友` });
    }
  }

  build() {
    Column({ space: 10 }) {
      Text('搜索用户').fontSize(18).fontWeight(FontWeight.Bold)
      
      Row() {
        TextInput({ placeholder: '输入用户名...', text: this.keyword })
          .layoutWeight(1)
          .onChange((v) => this.keyword = v)
          .onSubmit(() => this.handleSearch())
        
        Button('搜索')
          .onClick(() => this.handleSearch())
          .margin({ left: 8 })
          .height(36)
      }.width('100%')

      if (this.searchResults.length > 0) {
        List({ space: 8 }) {
          ForEach(this.searchResults, (u: User) => {
            ListItem() {
              Row() {
                SmartIcon({ name: u.username, iconSize: 36 }).margin({right: 10})
                Text(u.username).fontWeight(FontWeight.Bold).layoutWeight(1)
                
                Button('加好友').height(24).fontSize(10).backgroundColor('#28C76F').margin({right: 5})
                  .onClick(() => this.handleAddFriend(u))
                
                Button('私聊').height(24).fontSize(10).backgroundColor('#007DFF')
                  .onClick(() => {
                    this.onChat(u);
                    this.controller.close();
                  })
              }
              .width('100%').padding(10).backgroundColor('#F9F9F9').borderRadius(8)
            }
          })
        }
        .height(200)
        .width('100%')
      } else {
        Text('暂无搜索结果').fontSize(12).fontColor('#999').margin({top: 20, bottom: 20})
      }
      
      Button('关闭').backgroundColor('#CCC').width('100%').onClick(() => this.controller.close())
    }
    .padding(20).backgroundColor('#FFF').borderRadius(12).width('90%')
  }
}