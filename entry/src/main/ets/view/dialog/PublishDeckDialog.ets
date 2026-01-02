import { MockService } from '../../mock/MockService';
import { Deck } from '../../model/PlayerDeck';
import promptAction from '@ohos.promptAction';

@CustomDialog
export struct PublishDeckDialog {
  deck: Deck = {} as Deck;
  controller: CustomDialogController;
  
  @State title: string = '';
  @State description: string = '';

  aboutToAppear() {
    this.title = `分享: ${this.deck.name}`;
  }

  async handlePublish() {
    if (!this.title) {
      promptAction.showToast({ message: '请输入标题' });
      return;
    }
    const success = await MockService.publishDeck(this.deck, this.title, this.description);
    if (success) {
      promptAction.showToast({ message: '发布成功！' });
      this.controller.close();
    } else {
      promptAction.showToast({ message: '发布失败' });
    }
  }

  build() {
    Column({ space: 15 }) {
      Text('发布到社区').fontSize(18).fontWeight(FontWeight.Bold)
      
      TextInput({ placeholder: '帖子标题', text: this.title })
        .onChange((val) => this.title = val)
      
      TextArea({ placeholder: '心得体会 / 战术思路...' })
        .height(100)
        .onChange((val) => this.description = val)
      
      Row() {
        Button('取消').backgroundColor('#CCC').width('40%').onClick(() => this.controller.close())
        Blank()
        Button('发布').width('40%').onClick(() => this.handlePublish())
      }.width('100%')
    }
    .padding(20).backgroundColor('#FFF').borderRadius(12).width('90%')
  }
}