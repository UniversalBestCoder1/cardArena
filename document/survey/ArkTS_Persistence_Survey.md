# 关于 ArkTS 数据持久化方案的技术调研报告

## 1. 调研背景
在本项目（CardArena）的开发过程中，数据持久化是核心需求之一。在 Android (Java/Kotlin) 或 Node.js 开发中，开发者通常依赖成熟的 ORM（对象关系映射）框架（如 Room, Hibernate, TypeORM）来简化数据库操作，避免编写繁琐的 SQL 语句和手动对象映射。

然而，在迁移至 HarmonyOS Next (ArkTS) 技术栈时，我们发现生态中缺乏类似的成熟框架。为了确定最佳的工程实现路径，我们对 ArkTS 的语言特性及编译机制进行了深入调研。

## 2. 核心问题分析
传统 ORM 框架的核心“黑魔法”主要依赖于以下两种技术路径之一，而这两者在 ArkTS 中均受到显著限制：

1.  **运行时动态性限制 (Runtime Reflection)**：ArkTS 采用 AOT 静态编译且实施严格模式，禁止 `eval` 等动态执行，且反射能力被大幅阉割，无法像 Java 那样运行时动态分析类结构。
2.  **编译时代码生成限制 (Compile-time Code Generation)**：官方尚未开放用户自定义的注解处理器 API (APT)，无法通过简单的 `@Entity` 注解自动生成代码。

## 3. 架构方案深度演进
为了寻找最佳实践，我们从基础到高级，设计并评估了四种架构方案。**特别是“泛型仓储模式”，是我们针对 ArkTS 静态特性设计的一套纯面向对象方案。**

### 3.1 方案 A：硬闯 ORM (基于运行时反射)
*   **原理**：尝试移植 Java/JS 的反射逻辑，运行时动态映射。
*   **评估**：❌ **不可行**。ArkTS 严格模式下反射能力严重受限，且动态执行被禁，强行实现会导致极差的性能和不稳定性。

### 3.2 方案 B：构建插件 (编译时代码生成)
*   **原理**：编写 Hvigor 插件，解析 AST，自动生成辅助代码。
*   **评估**：⚠️ **成本过高**。需要深度定制构建系统，维护成本远超项目本身，不适合常规业务开发。

### 3.3 方案 C：泛型仓储模式 (Generic Repository Pattern) —— 👑 理论最佳 OO 方案
*   **原理**：
    在无法使用反射的情况下，利用 ArkTS 强大的 **泛型 (Generics)** 和 **抽象类 (Abstract Class)** 特性，强制实现对象与数据的解耦。
*   **设计原型**：
    ```typescript
    // 1. 定义泛型基类
    abstract class BaseRepository<T> {
      protected abstract tableName: string;
      // 核心：利用抽象方法强制子类实现转换逻辑，代替反射
      protected abstract toRow(entity: T): ValuesBucket;
      protected abstract fromRow(resultSet: ResultSet): T;

      async save(entity: T): Promise<void> {
        const data = this.toRow(entity);
        await DBHelper.insert(this.tableName, data);
      }
    }

    // 2. 业务子类实现
    class UserRepository extends BaseRepository<User> {
      protected tableName = 'users';
      protected toRow(user: User): ValuesBucket {
        return { 'name': user.name, 'age': user.age }; // 手动映射
      }
      // ...
    }
    ```
*   **优点**：
    *   **极致的类型安全**：业务层只接触 `User` 对象，完全隔离 `ValuesBucket`。
    *   **架构清晰**：符合领域驱动设计 (DDD) 思想，彻底分离业务逻辑与数据访问细节。
*   **缺点**：
    *   **样板代码膨胀**：每个实体类都需要手写一个对应的 Repository 和两个转换方法。在字段较多时，开发工作量成倍增加。
*   **评估**：🌟 **架构设计层面的最优解，但开发成本较高。**

### 3.4 方案 D：Helper 封装模式 (当前落地方案)
*   **原理**：封装底层 API，提供统一 CRUD 接口，业务层直接传递数据对象。
*   **评估**：✅ **工程落地最优解**。在开发周期有限且无需过度封装的场景下，拥有最高的性价比。

## 4. 结论与决策：为什么我们最终选择了方案 D？

尽管 **方案 C (泛型仓储模式)** 在架构设计上最为优雅，但本项目最终务实地选择了 **方案 D (Helper 封装)**。这一决策主要基于以下三点深刻的自我评估：

1.  **代码维护成本与“样板代码地狱”**：
    方案 C 虽然实现了类型安全，但在缺乏自动化代码生成工具（如 APT）支持的 ArkTS 中，意味着我们需要为每张表手动编写大量的 `toRow/fromRow` 映射代码。对于本项目 10+ 张数据表，这将产生数千行枯燥且容易出错的样板代码。
2.  **技术落地门槛与团队能力约束**：
    **（诚实评估）** 泛型仓储模式对开发者的抽象思维和架构规范执行力要求极高。在纯手动维护的情况下，极易因为某个字段的拼写错误或类型映射疏忽导致运行时崩溃。**团队经过评估，认为在现阶段的技术积累下，强行上马复杂的 Repository 模式容易导致“驾驭不住”，反而增加了由于架构复杂带来的 Bug 率。**
3.  **项目规模的适配性**：
    CardArena 属于中型应用，Helper 模式虽然牺牲了一定的 OO 纯度，但它简单、直接、足够高效。在有限的开发周期内，选择一个“团队能完全掌控”的方案，远比选择一个“看起来很高级但容易翻车”的方案更明智。

**总结：** 我们选择了方案 D，是基于**生态现状**与**团队能力**的双重考量下的**最优化妥协**。
