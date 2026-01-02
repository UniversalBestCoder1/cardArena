import { MockService } from '../../mock/MockService';
import promptAction from '@ohos.promptAction';

@CustomDialog
export struct AddSingleDialog {
  controller: CustomDialogController;
  onConfirm: () => void = () => {};
  
  @State keyword: string = '';
  @State searchResults: Record<string, Object>[] = [];
  @State selectedItem: Record<string, Object> | null = null;
  
  @State stock: number = 1;
  @State price: number = 0;

  async handleSearch() {
    if (!this.keyword.trim()) return;
    this.searchResults = await MockService.searchMasterDatabase(this.keyword);
  }

  async handleAdd() {
    if (!this.selectedItem) return;
    
    await MockService.addSingleFromMaster(this.selectedItem, this.stock, this.price);
    promptAction.showToast({ message: '添加成功' });
    this.onConfirm();
    this.controller.close();
  }

  build() {
    Column({ space: 10 }) {
      Text('新增单卡库存').fontSize(18).fontWeight(FontWeight.Bold)
      
      // Search
      Row() {
        TextInput({ placeholder: '搜索卡牌数据库...', text: this.keyword })
          .layoutWeight(1)
          .onChange((v) => this.keyword = v)
          .onSubmit(() => this.handleSearch())
        
        Button('搜索')
          .onClick(() => this.handleSearch())
          .margin({ left: 8 })
          .height(36)
      }.width('100%')

      // Results List
      if (this.searchResults.length > 0) {
        List({ space: 5 }) {
          ForEach(this.searchResults, (item: Record<string, Object>) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item['name'] as string).fontWeight(FontWeight.Bold).fontSize(14)
                  Text(`${item['game_type']} - ${item['card_code']} - ${item['rarity']}`).fontSize(10).fontColor('#666')
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                
                Radio({ value: item['id'] as string, group: 'master_cards' })
                  .checked(this.selectedItem?.['id'] === item['id'])
                  .onChange((isChecked) => {
                    if (isChecked) this.selectedItem = item;
                  })
              }
              .width('100%')
              .padding(8)
              .backgroundColor(this.selectedItem?.['id'] === item['id'] ? '#E3F2FD' : '#F9F9F9')
              .borderRadius(6)
              .onClick(() => this.selectedItem = item)
            }
          })
        }
        .height(150)
        .width('100%')
      } else {
        Text('请输入关键词搜索 (例如 "青眼", "Lotus")').fontSize(12).fontColor('#999').margin({top: 20, bottom: 20})
      }

      // Input details
      if (this.selectedItem) {
        Divider().margin({ top: 5, bottom: 5 })
        Text(`已选: ${this.selectedItem['name']}`).fontSize(12).fontColor('#007DFF').width('100%')
        
        Row() {
          Text('数量: ').width(60)
          TextInput({ text: this.stock.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((v) => this.stock = parseInt(v) || 0)
        }.width('100%')
        
        Row() {
          Text('单价: ').width(60)
          TextInput({ text: this.price.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((v) => this.price = parseInt(v) || 0)
        }.width('100%')
      }

      // Actions
      Row() {
        Button('取消').backgroundColor('#CCC').width('40%').onClick(() => this.controller.close())
        Blank()
        Button('确认入库')
          .width('40%')
          .enabled(this.selectedItem !== null)
          .backgroundColor(this.selectedItem ? '#007DFF' : '#CCC')
          .onClick(() => this.handleAdd())
      }.width('100%').margin({ top: 10 })
    }
    .padding(20).backgroundColor('#FFF').borderRadius(12).width('95%')
  }
}