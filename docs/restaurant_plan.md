# 餐厅功能实施计划 (Restaurant Feature Plan)

## Context

`restaurant_page.dart` 目前仅为占位符。本次需要按照设计稿 res_1~6 和 OpenAPI 实现完整的餐厅功能，涉及：
- Upload 页面增加 Campus Tab（餐厅搜索→选择→新建→添加菜品 Wizard 流程）
- 餐厅详情页（菜品列表展示）
- RestaurantPage 占位（今日推荐，暂无接口）
- 地图相关字段（经纬度/poi/hubId）全部使用 Mock 数据

---

## 设计稿对应功能说明

| 设计稿 | 对应功能 |
|--------|----------|
| res_1  | 上传流程 - 搜索餐厅（搜索框 + "NOW" 引导组件 + 虚拟键盘触发） |
| res_2  | 上传流程 - 餐厅列表（Campus / New Year 双 Tab，"没有找到？点击添加"） |
| res_3  | 上传流程 - 搜索结果（搜索框 + Enter 按钮 + 单条匹配展示） |
| res_4  | 餐厅详情页（基本信息、Favorite Shop/Add Tag 占位按钮、菜品列表） |
| res_5  | 新建店铺表单（左）+ 添加菜品表单（右），两步式 Wizard |
| res_6  | 应用双主题结构（普通 vs 新年），New Year Tab = 美食地图上传 |

---

## API 实现状态

| API | 方法 | 功能 | 是否实现 |
|-----|------|------|----------|
| `/restaurant/search` | GET | 搜索餐厅 | ✅ 实现 |
| `/restaurant/list` | GET | 餐厅列表 | ✅ 实现 |
| `/restaurant/add` | POST | 新建餐厅 | ✅ 实现 |
| `/restaurant/detail/{id}` | GET | 餐厅详情 | ✅ 实现 |
| `/restaurant/edit/{id}` | PUT | 编辑餐厅 | ❌ 本期不实现 |
| `/restaurant/delete/{id}` | DELETE | 删除餐厅 | ❌ 本期不实现 |
| `/foods/upload` | POST | 上传菜品 | ✅ 实现 |
| `/foods/list` | GET | 餐厅菜品列表 | ✅ 实现 |
| `/foods/tags/system` | GET | 获取系统标签 | ✅ 实现 |
| `/foods/{id}/tags/system` | POST | 为菜品添加系统标签 | ✅ 实现（上传时） |
| `/foods/{id}/tags/custom` | POST | 为菜品添加自定义标签 | ✅ 实现（上传时） |
| `/foods/{id}/favorite` | POST | 收藏菜品 | ✅ 实现 |
| `/foods/{id}/unfavorite` | POST | 取消收藏 | ✅ 实现 |
| `/foods/detail/{id}` | GET | 菜品详情 | ❌ 本期不实现（列表已含足够信息） |
| `/foods/my` | GET | 我的菜品 | ✅ 实现（Profile 上传 Tab） |
| `/foods/favorites` | GET | 收藏菜品列表 | ✅ 实现（Profile 收藏 Tab） |
| `/foods/edit/{id}` | PUT | 编辑菜品 | ❌ 本期不实现 |
| `/foods/delete/{id}` | DELETE | 删除菜品 | ❌ 本期不实现 |

---

## 实施步骤

### Step 1: 数据层建设

#### 1.1 新增 Models

**`lib/model/restaurant/restaurant.dart`**
```
Restaurant {
  id: int?
  name: String?
  address: String?
  cityId: int?
  gcjLng: double?
  gcjLat: double?
  hubId: int?
  poi: String?           // 对应 API 字段 "POI"
  pictureUrl: List<String>?
  createdAt: int?
  updatedAt: int?
}
```

**`lib/model/restaurant/restaurant_dto.dart`**
```
RestaurantDTO {
  name: String           // required
  address: String        // required
  cityId: int?
  gcjLng: double         // required, mock 值
  gcjLat: double         // required, mock 值
  hubId: int?            // mock 值
  poi: String?           // mock unique 值
  pictureUrl: List<String>?
}
```

**`lib/model/food/food_vo.dart`**
```
FoodVO {
  id: int?
  accountId: int?
  uploaderName: String?
  restaurantId: int?
  name: String?
  description: String?
  price: double?
  category: String?      // enum: STAPLE|DRINK|SNACK|DESSERT|SOUP|HOT_POT|GRILL|COLD_DISH|SIDE_DISH|OTHER
  pictureUrl: List<String>?
  systemTags: List<FoodTagSummaryVO>?
  myCustomTags: List<FoodTagSummaryVO>?
  isFavorite: bool?
  likesCount: int?
  createdAt: int?
  updatedAt: int?
}
```

**`lib/model/food/create_food_dto.dart`**
```
CreateFoodDTO {
  restaurantId: int      // required
  name: String           // required, maxLen 64
  description: String?   // maxLen 2000
  price: double?
  category: String?
  pictureUrl: List<String>  // required, 1-9 items
}
```

**`lib/model/food/food_tag.dart`**
```
FoodTagSummaryVO { id: int?, name: String? }
FoodTagViewVO { systemTags: List<FoodSystemTagVO>?, myCustomTags: List<FoodTagSummaryVO>? }
```

#### 1.2 新增 URL 常量

**`lib/core/constant/urls.dart`** — 追加：
```dart
// 餐厅端点
static const String restaurantSearch = '/restaurant/search';
static const String restaurantList = '/restaurant/list';
static const String restaurantAdd = '/restaurant/add';
static const String restaurantDetail = '/restaurant/detail';  // + /{id}

// 菜品端点
static const String foodsUpload = '/foods/upload';
static const String foodsList = '/foods/list';
static const String foodsSystemTags = '/foods/tags/system';
static const String foodDetail = '/foods';  // + /{id} 用于 tags/favorite 等子路径
```

#### 1.3 新增 Repositories

**`lib/repository/restaurant_repository.dart`**
- `searchRestaurants(String keyword, {int page=1, int pageSize=20})` → GET /restaurant/search
- `listRestaurants({int page=1, int pageSize=20})` → GET /restaurant/list
- `addRestaurant(RestaurantDTO dto)` → POST /restaurant/add
- `getRestaurantDetail(int id)` → GET /restaurant/detail/{id}

**`lib/repository/food_repository.dart`**
- `getFoodsByRestaurant(int restaurantId, {int page=1, int pageSize=20})` → GET /foods/list
- `uploadFood(CreateFoodDTO dto)` → POST /foods/upload
- `getSystemTags()` → GET /foods/tags/system
- `addSystemTags(int foodId, List<int> tagIds)` → POST /foods/{id}/tags/system
- `addCustomTags(int foodId, List<String> names)` → POST /foods/{id}/tags/custom
- `favoriteFood(int foodId)` → POST /foods/{id}/favorite
- `unfavoriteFood(int foodId)` → POST /foods/{id}/unfavorite
- `getMyFoods({int page=1, int pageSize=20})` → GET /foods/my
- `getMyFavorites({int page=1, int pageSize=20})` → GET /foods/favorites

#### 1.4 更新 Provider

**`lib/provider/repository_provider.dart`** — 追加：
```dart
@Riverpod(keepAlive: true)
RestaurantRepository restaurantRepository(Ref ref) =>
    RestaurantRepository(ref.read(apiProvider));

@Riverpod(keepAlive: true)
FoodRepository foodRepository(Ref ref) =>
    FoodRepository(ref.read(apiProvider));
```

---

### Step 2: RestaurantPage 占位

**`lib/page/restaurant_page.dart`**（替换现有占位符）

- 显示"今日推荐"标题（对应 res_6 第一张 Recommend 风格）
- 主体显示空状态 + 提示文案（"精彩内容即将上线"）
- 保持与其他页面一致的 AppBar 风格

---

### Step 3: Upload Page 重构（嵌入 Campus 流程）

**`lib/page/upload_page.dart`** — 重构

当前 upload_page 显示 New Year 上传（活动食物）。重构后：
- 顶部新增 Campus / New Year 两个 Tab（样式参照 res_2）
- **Campus Tab** → 进入餐厅搜索+菜品上传 Wizard（见 Step 4）
- **New Year Tab** → 保留现有活动食物上传 UI（基本不变）

---

### Step 4: Campus 上传 Wizard（新增页面）

Wizard 流程：`搜索餐厅 → 选择/新建 → 添加菜品 → 完成`

#### 4.1 `lib/page/restaurant_search_page.dart`（新建）
对应 res_1 + res_3

- 搜索框（TextFormField）
- 搜索前显示"HOW Step1"引导卡片（res_1 风格）
- 输入后显示搜索结果列表（res_3）
- 每项可点击进入餐厅详情页
- 底部 "没有找到？点击添加" → 跳转 `AddRestaurantPage`
- 调用 `RestaurantRepository.searchRestaurants(keyword)`

#### 4.2 `lib/page/restaurant_list_page.dart`（新建）
对应 res_2 Campus Tab 的列表

- 餐厅卡片（logo、名称、评分占位、地址、月售占位）
- "没有找到你想的店铺？点击添加"底部栏（含 Add 按钮）
- 调用 `RestaurantRepository.listRestaurants()`

#### 4.3 `lib/page/add_restaurant_page.dart`（新建）
对应 res_5 左侧"新建店铺"

表单字段：
- 选择店铺地址（UI 占位按钮，显示 Mock 地址文本）
- 店铺名称（必填）
- 店铺描述（选填）
- 店铺照片（图片选择，1-9 张，调用 upload presign）
- 店铺标签（UI 预留，暂不对接）
- Next 按钮

Mock 地址处理：
- gcjLng: 117.0653（济南市历下区）
- gcjLat: 36.6726
- hubId: 1
- POI: `"SDU_${DateTime.now().millisecondsSinceEpoch}"` 保证唯一性

完成后调用 `RestaurantRepository.addRestaurant(dto)` → 成功后携带 restaurantId 跳转 `AddFoodPage`

#### 4.4 `lib/page/add_food_page.dart`（新建）
对应 res_5 右侧"添加菜品"

表单字段：
- 菜品名称（必填）
- 菜品描述（选填）
- 菜品标签（系统标签多选 + 自定义标签输入，调用 `/foods/tags/system`）
- 图片（至少 1 张，调用 upload presign）
- Next 按钮（可选，添加更多菜品）
- Finish 按钮（提交）

完成后调用：
1. `FoodRepository.uploadFood(CreateFoodDTO)` → 获取 foodId
2. 若有系统标签：`FoodRepository.addSystemTags(foodId, tagIds)`
3. 若有自定义标签：`FoodRepository.addCustomTags(foodId, names)`

---

### Step 5: 餐厅详情页

**`lib/page/restaurant_detail_page.dart`**（新建）
对应 res_4

布局：
- 顶部：餐厅图片（轮播或单图）
- 餐厅名称 + 地址 + 评分（评分为 UI 占位，无接口）
- Favorite Shop 按钮（UI 占位，暂无功能）
- Add Tag 按钮（UI 占位，暂无功能）
- 菜品列表（分页，调用 `/foods/list?restaurantId=xxx`）
  - 每个菜品卡片：图片、名称、价格、标签、收藏按钮（调用 favorite/unfavorite）

调用：
- `RestaurantRepository.getRestaurantDetail(id)` → 餐厅信息
- `FoodRepository.getFoodsByRestaurant(restaurantId)` → 菜品列表

---

### Step 6: 路由更新

**`lib/router/app_router.dart`** — 追加路由

```dart
GoRoute(
  path: '/restaurant/:id',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return RestaurantDetailPage(restaurantId: id);
  },
),
```

导航来源：
- 餐厅搜索页点击某条结果 → `context.push('/restaurant/$id')`
- 餐厅列表页点击某条 → 同上

---

### Step 7: Profile 页 Tab 数据接入

由于 `/foods/my` 和 `/foods/favorites` 已有接口，需同步更新 Profile 页：

**`lib/page/profile_page.dart`**（更新）
- "上传" Tab → 调用 `FoodRepository.getMyFoods()` 替换当前静态占位，展示用户上传的菜品卡片列表（含图片、名称、餐厅名）
- "收藏" Tab → 调用 `FoodRepository.getMyFavorites()` 替换当前静态占位，展示收藏菜品列表
- 两个 Tab 均支持下拉刷新和分页加载

---

## Mock 数据规范

| 字段 | Mock 值 | 说明 |
|------|---------|------|
| gcjLng | 117.0653 | 济南市历下区（山大软件园附近） |
| gcjLat | 36.6726 | 同上 |
| hubId | 1 | 固定 Hub |
| POI | `"SDU_${timestamp}"` | 每次新建餐厅生成 unique 值 |

---

## 不实现的功能（本期范围外）

- Favorite Shop（收藏餐厅）：UI 占位按钮，等后端接口
- Add Tag on 餐厅详情：UI 占位，等设计确认
- 餐厅编辑 / 删除
- 菜品编辑 / 删除 / 详情页
- New Year Tab 的年夜饭上传流程
- RestaurantPage 的今日推荐数据（无接口，仅占位 UI）

---

## 验证方式

1. **Upload Campus 流程**：点击上传 → Campus Tab → 搜索餐厅 → 选择结果 → 进入餐厅详情；或"点击添加" → 填写新建店铺表单 → Next → 添加菜品表单 → Finish → 验证 `/restaurant/add` 和 `/foods/upload` 两个请求发出
2. **餐厅详情页**：从搜索结果点击进入，验证菜品列表加载（`/foods/list`）、收藏按钮切换（`/foods/{id}/favorite` & `/unfavorite`）
3. **RestaurantPage**：底部 Tab 切换到餐厅图标，确认占位 UI 正常显示
4. **Mock 数据**：新建餐厅时，网络请求中确认 gcjLng/gcjLat/hubId/POI 均为 mock 值
