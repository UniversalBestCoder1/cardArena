# CardArena (决斗链接 - 线下版)

> 软件工程课程设计项目：线下桌游/卡牌店管理系统客户端

## 1. 项目简介
CardArena 是一款基于 HarmonyOS (ArkTS) 开发的线下卡牌对战管理 App。主要服务于游戏王 (Yu-Gi-Oh!) 和万智牌 (MTG) 玩家，提供赛事报名、卡组租借、桌位预约以及卡牌价格查询等功能。

本项目采用 **纯原生 ArkTS** 开发，遵循 MVVM 架构模式，并使用 MockService 模拟后端 API 交互。

## 2. 核心功能
*   **🏆 赛事大厅 (HomeView)**: 查看近期店赛日程，支持一键报名扣费模拟。
*   **📦 资源预约 (BookingView)**:
    *   **卡组租借**: 浏览店铺闲置卡组，实时租用/归还，自动计算租金。
    *   **桌位预订**: 可视化查看桌位状态（Demo）。
*   **🔍 卡牌百科 (WikiView)**:
    *   模拟对接国内权威数据库（旅法师营地/集换社）。
    *   支持关键字搜索，展示卡图、效果文本及**实时人民币均价**。
*   **👤 个人中心 (ProfileView)**: 玩家战绩统计、Konami ID 管理、钱包余额。

## 3. 技术架构
本项目完全遵循鸿蒙应用开发规范：

*   **开发语言**: ArkTS (TypeScript 扩展)
*   **UI 框架**: ArkUI (声明式 UI)
*   **架构模式**:
    *   **Model**: 定义 `Card`, `Tournament`, `RentableDeck` 等数据结构。
    *   **View**: `HomeView`, `WikiView` 等界面组件。
    *   **Service**: `MockService` 负责拦截请求，返回本地 JSON 数据（模拟网络延迟）。

### 目录结构
```
entry/src/main/ets/
├── common/       # 公共工具类
├── mock/         # 模拟数据服务 (MockService)
├── model/        # 数据模型接口 (Card, Tournament...)
├── pages/        # 页面入口 (Index.ets)
├── view/         # 业务视图组件 (HomeView, WikiView...)
└── viewmodel/    # 业务逻辑 (可选扩展)
```

## 4. 接口文档
本项目包含完整的 RESTful API 接口设计规范，详见根目录下的 `CardArena_API_Docs.json` (Postman Collection)。

## 5. 运行说明
1.  使用 **DevEco Studio** 打开项目根目录。
2.  确保 SDK 版本兼容 HarmonyOS Next / API 9+。
3.  点击 "Run 'entry'" 即可在模拟器或真机运行。
4.  *(可选)* 若需替换图片，请将 png 图片放入 `entry/src/main/resources/base/media/` 并修改 `MockService.ets` 中的引用。
