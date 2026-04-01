# eat_what_app 官方推荐架构重构计划（v3）

## Summary
- 目标是把当前项目重构为 Flutter 官方推荐的两层主模型：`UI Layer = View + ViewModel`，`Data Layer = Repository + 可选 DataSource`。不默认引入 `domain/`，也不为每个数据模型强制补 `Entity`。
- 目录主轴采用“`features/` 为主，`shared/` 为辅”：
  - `features/` 只放拥有独立路由或完整用户流程的模块。
  - `shared/` 只放没有独立页面、且被多个 feature 的 ViewModel 直接依赖的数据能力。
- `Riverpod` 本轮保留，但统一职责：
  - `Provider` 只做依赖注入。
  - `Notifier / AsyncNotifier` 只做 ViewModel。
  - 页面仅保留纯临时 `setState`，网络加载、提交、分页、乐观更新、错误反馈全部迁入 ViewModel。
- `Freezed` 本轮只强制覆盖：
  - `UiState`
  - 少量需要跨 Repository 聚合的 presentation 专用模型
  不对现有 `Request / Response / DTO / VO` 做一刀切重写。
- 计划文档路径固定为 `docs/official_feature_layer_refactor_plan.md`。

## Key Changes
- 顶层结构固定为：

```text
lib/
  main.dart
  app/
    bootstrap.dart
    app.dart
    router/
      app_router.dart
      route_paths.dart
    shell/
      app_shell_page.dart
      app_shell_view_model.dart
      widgets/
  core/
    network/
      request_client.dart
      api_parser.dart
      interceptors/
    error/
    theme/
    constant/
  shared/
    location/
      data/
        models/
        data_sources/
        repositories/
        providers.dart
    food/
      data/
        models/
        repositories/
        providers.dart
  features/
    auth/
      presentation/
        pages/
        view_models/
        widgets/
      data/
        models/
        data_sources/
        repositories/
        providers.dart
    home/
      presentation/
        pages/
        view_models/
        widgets/
      data/
        local/
    upload/
      presentation/
        pages/
        view_models/
        widgets/
      data/
        models/
        data_sources/
        repositories/
        providers.dart
    restaurant/
      presentation/
        pages/
        view_models/
        widgets/
      data/
        models/
        repositories/
        providers.dart
    foodie_map/
      presentation/
        pages/
        view_models/
        widgets/
      data/
        models/
        repositories/
        providers.dart
    profile/
      presentation/
        pages/
        view_models/
        widgets/
      data/
        models/
        repositories/
        providers.dart
    map/
      presentation/
        pages/
```

- 不预建 `presentation/models/` 目录。聚合型 UI 专用模型按需放在对应 ViewModel 旁边，例如：
  - `profile_overview_view_model.dart`
  - `profile_overview_state.dart`
  - `profile_overview_models.dart`
- `shared/` 归属规则固定为：
  - 没有独立路由页面。
  - 被两个或以上 feature 的 ViewModel 直接依赖。
  - 当前明确进入 `shared/` 的只有：
    - `location`
    - `food`
- `shared/` 依赖规则固定为：
  - `features/* -> shared/*` 允许。
  - `shared/* -> features/*` 禁止。
  - `shared/* -> core/*` 允许。
  - `features/* -> features/*` 默认禁止；若确有复用需求，应先上提到 `shared/`。
- `shared/food` 的允许依赖明确为：
  - `features/upload -> shared/food` 允许，用于提交与写入 food 数据。
  - `features/profile -> shared/food` 允许，用于读取我的菜品、收藏、标签。
  - `features/restaurant -> shared/food` 允许，用于读取餐厅菜品列表、收藏状态。
  - `shared/food -> features/*` 禁止。
- 对外行为保持不变：
  - 现有路由路径全部保持兼容。
  - 后端接口路径、参数、响应结构不改。
- 内部接口变化固定为：
  - `authProvider` 改为 `AuthSessionViewModel`
  - `navigation_bar_provider` 改为 `AppShellViewModel`
  - `foodie_map_page_controller` 改为 `FoodieMapViewModel`
  - `upload_page_controller` 改为 `ActivityUploadViewModel`
  - 所有页面停止直接读取 Repository Provider
- 数据层命名规则改为：
  - 默认只用 `Repository`
  - 只有在“多数据源组合”或“平台/本地存储边界”场景下才拆 `DataSource`
  - 不再用 `Service` 作为统一术语
- DataSource 使用门槛固定为：
  - 需要组合两个或以上外部来源
  - 需要隔离平台能力或本地存储
  - 需要在多个 Repository 间共享同一种低层访问逻辑
  - 否则 Repository 可直接调用 `RequestClient`
- transport model 处理规则固定为：
  - `Request / Response / DTO / VO` 全部留在 `data/models/`
  - ViewModel 可以直接消费 Repository 返回的数据模型
  - 只有当页面需要跨多个 Repository 聚合数据时，才在对应 ViewModel 旁定义 UI 专用聚合模型
- `Freezed` 使用规则固定为：
  - `*UiState` 必须用 `Freezed`
  - 聚合型 presentation 专用模型优先用 `Freezed`
  - transport model 默认不改，除非某个高频模型在 ViewModel 层确实需要不可变拷贝语义

## Implementation Changes
- `app` 层重组：
  - `lib/main.dart` 只保留 bootstrap 与 `ProviderScope` 装配。
  - `lib/router/app_router.dart` 迁到 `app/router/`，并新增 `route_paths.dart` 收口路径常量。
  - `lib/page/main_page.dart` 与底部导航组件迁入 `app/shell/`。
  - shell 显隐状态由 `AppShellViewModel` 管理，页面不再直接读顶层导航 provider。
- `features/auth`：
  - 吸收登录、注册、忘记密码、认证页、webview 认证页。
  - `AuthSessionViewModel` 负责 token 恢复、登录、注册、登出与 router redirect 状态。
  - `SecureStorageUtil` 下沉为 `TokenStorageDataSource`，因为它是明确的本地存储边界。
  - `AuthRepository` 保留为 feature 内数据边界；认证校验、邮件发送、网页登录返回轮询等页面逻辑从 Widget 中迁出。
- `shared/location`：
  - 吸收省市接口与设备定位能力。
  - `Geolocator` 与权限逻辑下沉到 `DeviceLocationDataSource`。
  - 省市接口可保留 `LocationRepository -> RequestClient` 的单源结构；如后续需要组合远端省市与本地定位，再由 Repository 聚合。
  - `ProvinceResponse / CityResponse` 保留在 data/models，页面通过 ViewModel 获取。
- `shared/food`：
  - 吸收现有 `FoodRepository`、`FoodVO`、标签 VO 等数据能力。
  - 原因是它没有独立页面，却被 `profile`、`restaurant`、`upload` 多个 feature 直接依赖。
  - `favorite / unfavorite / getMyFoods / getMyFavorites / getFoodsByRestaurant / getSystemTags` 全部从这里对外提供。
  - `shared/food` 只提供数据能力，不承载页面、路由、ViewModel。
- `features/restaurant`：
  - 负责 `restaurant` 路由页面与餐厅详情展示。
  - 餐厅搜索与详情数据仍归 restaurant feature 所有；`upload` 可直接依赖它的 Repository。
  - `restaurant_detail_page.dart` 的首屏并发加载、分页、收藏回滚全部迁入 `RestaurantDetailViewModel`。
  - 单源 HTTP 场景下不强制拆 `RestaurantDataSource`，Repository 可直接调用 `RequestClient`。
- `features/upload`：
  - 吸收 `upload_page.dart`、`restaurant_search_page.dart`、`add_restaurant_page.dart`、`add_food_page.dart`。
  - upload 内部拆成多个 ViewModel：
    - `UploadEntryViewModel`
    - `RestaurantSearchViewModel`
    - `AddRestaurantViewModel`
    - `AddFoodViewModel`
    - `ActivityUploadViewModel`
  - `SharedPreferences` 的引导提示状态下沉为 `RestaurantSearchHintDataSource`。
  - 图片 presign / raw upload 如仍依赖 `RequestClient.raw()`，保留为 upload 内部 `DataSource`，不暴露到 ViewModel 层。
  - upload 允许直接依赖 `shared/food` 与 `features/restaurant` 的数据边界，不反向暴露自己的内部实现。
- `features/foodie_map`：
  - 维持当前“页面状态集中管理”的方向，但统一命名为 `FoodieMapViewModel` 与 `FoodieMapFoodListViewModel`。
  - 省份列表改走 `shared/location`，不再和活动美食仓库混在一起。
  - 活动美食分页、点赞、错误反馈都进入 `Freezed UiState`。
  - 页面保留少量滚动监听与局部交互 `setState`，但不再直接处理业务异步。
- `features/profile`：
  - 吸收 `profile_page.dart`、`profile_info_page.dart`、`profile_history_page.dart`、`profile_tag_library_page.dart`。
  - 大文件必须拆成：
    - `page`
    - `view_model`
    - `ui_state`
    - `sections/widgets`
    - 必要时的聚合模型文件
  - `ProfileOverviewViewModel` 管首页聚合。
  - `ProfileInfoViewModel` 管资料编辑与头像上传。
  - `ProfileHistoryViewModel` 管分页历史。
  - `ProfileTagLibraryViewModel` 管标签库。
  - 当前页面中所有直接读取 `UserRepository`、`FoodRepository` 的逻辑全部迁出。
- `features/home` 与 `features/map`：
  - `home` 新增 `HomeViewModel`，把轮播静态数据从页面中移到 `data/local/`。
  - `map` 保持轻量页面，但目录结构对齐，方便未来扩展。
- 迁移顺序固定为：
  1. 覆盖 `docs/official_feature_layer_refactor_plan.md`。
  2. 建立 `app/core/shared/features` 新骨架与路径常量。
  3. 迁移 `auth` 和 router，会话链路先稳定。
  4. 迁移 `shared/location` 与 `shared/food`。
  5. 迁移 `upload`、`restaurant`、`foodie_map` 三条最混乱链路。
  6. 迁移 `profile` 并拆超大页面文件。
  7. 迁移 `home` 与 shell。
  8. 清理旧顶层 `page/controller/provider/repository/model/widget/util/router`。
  9. 统一 imports、生成代码、回归验证。
- 旧目录清理标准固定为：
  - 不保留长期兼容导出层。
  - 最终项目不得残留顶层 `page/ controller/ provider/ repository/ model/ widget/ util/ router/` 目录。
  - 页面层不得再 import `repository_provider.dart` 这类总线文件。

## Test Plan
- 本轮测试目标是“证明重构前后行为一致”，不是补齐完整产品测试体系。
- 必做回归测试固定为：
  - 路由重定向：
    - 未登录进入受保护页面跳 `/login`
    - 已登录从 `/splash` 或 auth 路由进入 `/home`
  - upload 主流程：
    - 餐厅搜索
    - 找不到餐厅后进入添加餐厅
    - 餐厅详情进入添加菜品
    - 新年上传表单校验、成功提示、失败提示
  - restaurant 详情：
    - 首屏并发加载
    - 下拉刷新
    - 分页
    - 收藏乐观更新失败回滚
  - foodie_map：
    - 首屏初始化
    - 定位权限拒绝提示
    - 省份切换
    - 点赞失败回滚
  - profile：
    - 首页加载
    - 编辑资料后返回刷新
    - 历史分页
    - 标签库加载
  - shell：
    - 底部导航显隐
    - branch 切换与保活
- 必做单元测试只覆盖“新引入的高风险边界”：
  - `AuthSessionViewModel`
  - `RestaurantDetailViewModel`
  - `FoodieMapViewModel`
  - `ActivityUploadViewModel`
  - `ProfileOverviewViewModel`
  - `TokenStorageDataSource`
  - `RestaurantSearchHintDataSource`
  - `DeviceLocationDataSource`
- 验收标准固定为：
  - `dart analyze` 无错误
  - 生成代码齐全
  - 关键路由行为一致
  - 页面层不再直接读取 Repository
  - `SharedPreferences`、`SecureStorage`、`Geolocator`、`RequestClient.raw()` 不再出现在 ViewModel 或页面层
  - 有最小必要的回归测试，不额外把重构扩大成完整测试补全工程

## Assumptions
- 本轮严格遵守 Flutter 官方推荐的两层主模型，不默认引入 `domain/`。
- Repository 是主要边界；只有在确实需要组合多个数据源或隔离平台/本地存储时，才引入 `DataSource`。
- `auth` 放在 `features/auth`，因为它拥有独立页面和完整用户流程；`location` 与 `food` 放在 `shared/`，因为它们没有独立页面且被多个 feature 共用。
- 不预建 `presentation/models/` 目录；聚合型模型按需与对应 ViewModel 同目录放置。
- `Freezed` 只强制覆盖 `UiState` 与少量聚合型 presentation model，不扩展为全量 DTO/Response 改造。
- 页面命名本轮不强制全量 `Page -> Screen`，优先解决依赖边界与职责归属。
