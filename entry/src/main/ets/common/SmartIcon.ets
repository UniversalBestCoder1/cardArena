@Component
export struct SmartIcon {
  @Prop name: string;
  @Prop iconSize: number = 60; // [Fixed] 重命名以避免冲突
  @Prop colorOverride: string = '';

  // 简单的哈希颜色生成器
  private getColor(): string {
    if (this.colorOverride) return this.colorOverride;
    
    const colors = [
      '#FF9F43', // 橙
      '#FECA57', // 黄
      '#FF6B6B', // 红
      '#48DBFB', // 蓝
      '#1DD1A1', // 绿
      '#5F27CD', // 紫
      '#54A0FF', // 浅蓝
      '#2E86DE'  // 深蓝
    ];
    let hash = 0;
    for (let i = 0; i < this.name.length; i++) {
      hash = this.name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }

  // 获取首字母/首字
  private getInitial(): string {
    if (!this.name) return '?';
    // 过滤掉【YGO】这种前缀
    const cleanName = this.name.replace(/【.*?】/g, '').trim();
    return cleanName.charAt(0).toUpperCase();
  }

  build() {
    Stack() {
      // 背景
      Rect()
        .width(this.iconSize)
        .height(this.iconSize)
        .radius(this.iconSize / 4) // 圆角矩形
        .fill(this.getColor())
      
      // 文字
      Text(this.getInitial())
        .fontSize(this.iconSize * 0.5)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }
}
