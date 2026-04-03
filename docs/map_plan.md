# 校园周边精选 / 地图聚合页 — 开发计划

## 一、功能概述

基于百度地图 Flutter SDK，展示学校周边商户（Restaurant）的地理分布。后端已将相邻商户归入「聚合点」（Hub），前端以 Marker 形式在地图上展示 Hub，点击后展开该 Hub 下的商户列表。支持标签筛选。

---

## 二、前置准备

### 2.1 API 补充（需后端配合）

当前 API 缺少以下接口，需要与后端沟通确认或新增：

| 缺失接口 | 说明 | 建议定义 |
|---------|------|---------|
| 查询 Hub 下的店铺列表 | 点击聚合点后展示商户卡片列表 | `GET /restaurant/list?hubId={id}&tag={tag}&page=1&pageSize=20` |
| 标签列表 | 筛选面板需要展示可选标签 | `GET /tag/list` |
| Hub 统计摘要 | 聚合点卡片上显示店铺数量、评分分布、月点击量 | 在 `/hub/list` 返回中追加 `restaurantCount`、`highRatingCount`、`monthlyClicks` 字段，或单独接口 `GET /hub/stats/{id}` |
| 店铺收藏 | 爱心按钮收藏/取消收藏 | `POST /restaurant/favorite/{id}`、`DELETE /restaurant/favorite/{id}` |

### 2.2 坐标系确认

- 后端坐标：**GCJ-02**（国测局坐标），字段为 `gcjLng` / `gcjLat`
- 百度地图默认：**BD-09**
在 SDK 初始化时指定坐标类型为GCJ

### 2.3 百度地图 Flutter SDK 集成

- 确认 `flutter_bmfmap` / `flutter_bmfbase` 等依赖已接入
- 确认 iOS / Android 的百度地图 AppKey 已配置
- 确认定位权限（`location`）已申请

---

## 三、任务分解

### Phase 1：基础地图 + Hub Marker 展示

**目标**：进入地图页后能看到所有聚合点标注

#### Task 1.1 — 地图页骨架搭建
- 新建页面 `MapAggregationPage`
- 使用 `BMFMapWidget` 初始化地图，设定初始中心点为校区中心坐标
- 设定合适的初始 zoom level（建议 14-15 级，覆盖校区周边范围）
- 底部 TabBar 中「地图」Tab 跳转到本页面

#### Task 1.2 — Hub 列表接口对接
- 封装 API 调用：`GET /hub/list?page=1&pageSize=100`
- 定义 `Hub` Model 类，解析 JSON 响应
- 处理分页逻辑（如果 Hub 数量 > 100 则需要加载全部）

#### Task 1.3 — 自定义 Marker 绘制
- 使用 `Canvas` 绘制红色圆形 + Hub 名称或数量文字
- 转换为 `BMFMarker` 可用的图片（`ui.Image` → `Uint8List`）
- 遍历 Hub 列表，为每个 Hub 创建 Marker 并添加到地图上
- **坐标转换**：GCJ-02 → BD-09（在这一步统一处理）

#### Task 1.4 — Marker 点击事件
- 注册 `BMFMapWidget.onClickedMapMarker` 回调
- 点击后暂时只做 `print` 输出，验证交互通路

**交付物**：地图上能看到所有 Hub 的红色标注点，点击有响应

---

### Phase 2：点击聚合点 → 展开详情

**目标**：点击某个 Hub Marker 后，地图放大并弹出商户列表

#### Task 2.1 — 地图放大动画
- 点击 Marker 后，调用 `mapController.animateMapStatus()` 将地图中心移至该 Hub 坐标
- zoom level 放大到 16-17 级
- 如果 Hub 有 `boundary` 数据，可以用 bounding box 来自适应缩放

#### Task 2.2 — 底部商户列表弹窗
- 使用 `DraggableScrollableSheet` 或 `showModalBottomSheet`
- 初始高度占屏幕 40%，可拖拽展开到 85%
- 顶部显示 Hub 名称 + 统计信息（店铺数、月点击量等）
- 列表使用 `ListView.builder` 懒加载

#### Task 2.3 — 商户列表接口对接
- 调用 `GET /restaurant/list?hubId={id}&page=1&pageSize=20`（待后端新增）
- 定义 `Restaurant` Model 类
- 列表卡片 UI：封面图、店名、地址、评分、收藏按钮

#### Task 2.4 — 商户卡片点击 → 跳转店铺详情
- 点击列表中某个商户卡片，跳转到店铺详情页
- 传递 `restaurantId` 参数

**交付物**：点击聚合点后地图放大，底部弹出商户列表，可点击进入详情

---

### Phase 3：筛选功能

**目标**：右上角筛选按钮，按标签过滤地图上的内容

#### Task 3.1 — 筛选按钮 UI
- 地图右上角悬浮一个筛选图标按钮
- 点击弹出筛选面板（`showModalBottomSheet` 或侧滑抽屉）

#### Task 3.2 — 标签列表加载
- 调用 `GET /tag/list`（待后端新增）获取所有标签
- 以 Chip / Tag 网格形式展示，支持多选

#### Task 3.3 — 筛选逻辑联动
- 选中标签后，重新请求 `/hub/list` 或 `/restaurant/list` 并带上标签参数
- 刷新地图 Marker（移除旧的，添加新的）
- 如果当前有展开的商户列表，也同步刷新

**交付物**：可以按标签筛选，地图和列表联动更新

---

### Phase 4：体验优化

#### Task 4.1 — 地图拖动/缩放时刷新
- 监听 `onMapStatusChangeFinish`，获取当前可视区域 bounding box
- 判断是否需要加载更多数据（如果 Hub 总量大，可按视野范围筛选）
- 加防抖（debounce），避免频繁请求

#### Task 4.2 — 加载状态 & 空状态
- 地图加载中显示 loading 指示器
- 商户列表为空时显示友好提示
- 网络错误时显示重试按钮

#### Task 4.3 — Marker 视觉优化
- 不同 Hub 的商户数量 → 不同大小/颜色的 Marker
- 选中状态的 Marker 高亮（放大或变色）
- 当 zoom level 足够大时，显示单个商户 Marker 而非聚合点

#### Task 4.4 — 收藏功能
- 商户卡片的爱心按钮，点击调用收藏接口
- 状态即时切换，用乐观更新策略

---

## 四、技术要点总结

### 关键依赖

| 依赖 | 用途 |
|------|------|
| `flutter_bmfmap` | 百度地图 Flutter 插件 |
| `flutter_bmfbase` | 百度地图基础库 |
| `flutter_bmflocation` | 定位（如需获取用户当前位置） |

### 核心架构

```
MapAggregationPage
├── BMFMapWidget（地图层）
│   ├── Hub Markers（聚合点标注）
│   └── Restaurant Markers（放大后的单店标注）
├── FilterButton（右上角筛选按钮）
│   └── FilterPanel（标签筛选面板）
└── HubDetailSheet（底部弹窗）
    ├── HubHeader（Hub 名称 + 统计）
    └── RestaurantList（商户列表）
        └── RestaurantCard（单个商户卡片）
```

### 状态管理建议

使用 `Riverpod` 或 `Bloc` 管理以下状态：
- `hubListState` — 当前地图上的 Hub 列表
- `selectedHubState` — 当前选中的 Hub
- `restaurantListState` — 当前展开的商户列表
- `filterState` — 当前选中的筛选标签
- `mapViewState` — 当前地图视野（center、zoom）

---

## 五、里程碑 & 预估工期

| 阶段 | 内容 | 预估时间 | 前置条件 |
|------|------|---------|---------|
| Phase 0 | 后端接口补充 + 坐标系确认 | 1-2 天 | 与后端沟通 |
| Phase 1 | 基础地图 + Hub Marker | 2-3 天 | Phase 0 完成 |
| Phase 2 | 点击展开 + 商户列表 | 2-3 天 | Phase 1 完成 |
| Phase 3 | 筛选功能 | 1-2 天 | 标签接口就绪 |
| Phase 4 | 体验优化 | 2-3 天 | 可与 Phase 3 并行 |

---

## 六、风险 & 注意事项

1. **坐标系不一致**是最容易踩的坑，务必在 Phase 1 的 Task 1.3 中彻底解决，否则后续所有 Marker 位置都会偏移。

2. **百度地图 Flutter SDK 无内置聚合组件**，但你的后端已经用 Hub 概念做了服务端聚合，所以前端只需要渲染 Marker，不需要自己实现聚合算法。

3. **Hub 的 `boundary` 字段是 JTS MultiPolygon**，JSON 序列化后体积较大。如果只是用来做地图缩放适配，可以只用 `envelope`（bounding box）的 `minx/maxx/miny/maxy` 即可，不需要解析完整的多边形几何。

4. **性能**：如果 Hub 数量超过 200+，需要考虑按可视区域加载（视野裁剪），避免一次性创建过多 Marker 导致地图卡顿。