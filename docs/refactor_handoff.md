# 架构重构交付文档

**分支：** `refactor/official-feature-architecture`
**日期：** 2026-03-30
**状态：** Phase 1–3 + Phase 5（部分）已完成，`flutter analyze` 剩余 **24 个错误**待修

---

## 一、重构目标

将项目从"混用模式"统一为：

| 层 | 新模式 |
|---|---|
| UiState | `@freezed abstract class XxxState` — 全部 Freezed，无手写 copyWith |
| ViewModel | `@riverpod class XxxViewModel extends _$XxxViewModel`（Notifier 模式） |
| 页面业务状态 | 全部由 `ref.watch(xxxViewModelProvider)` 驱动，页面内不再有业务 `setState` |
| 页面本地 UI 状态 | 保留 `setState`（图片 bytes 预览、表单 controller、弹窗内临时选择等） |
| 省市数据依赖 | 全部走 `shared/location/providers.dart` → `locationRepositoryProvider` |

---

## 二、已完成的工作

### Phase 1 — 低风险提取
- **`lib/app/shell/widgets/animated_branch_container.dart`** ← 从 `app_router.dart` 剪切的 120 行动画 Widget
- **`lib/app/router/app_router.dart`** — 删除内联动画类，改用新文件引用

### Phase 2 — Freezed State 文件（已有 Notifier 的 VM）
新建以下 state 文件（全部为 `@freezed abstract class`）：

| 文件 | 包含 |
|---|---|
| `lib/app/shell/app_shell_state.dart` | `AppShellState` |
| `lib/features/upload/presentation/view_models/activity_upload_state.dart` | `ActivityUploadState`, `ActivityUploadFeedback`, `ActivityUploadFeedbackKind` |
| `lib/features/foodie_map/presentation/view_models/foodie_map_state.dart` | `FoodieMapPageState`, `FoodieMapFoodListState`, `FoodieMapFeedback`, `FoodieMapFeedbackKind` |
| `lib/features/restaurant/presentation/view_models/restaurant_detail_state.dart` | `RestaurantDetailState` |

对应 VM 修改：删除内联 state 类 + sentinel 常量，改用 import。

### Phase 3 — 普通类 VM → Notifier + Freezed State

以下 ViewModel 已完全重写为 `extends _$XxxViewModel`：

| ViewModel | State 文件 |
|---|---|
| `profile_history_view_model.dart` | `profile_history_state.dart` |
| `profile_info_view_model.dart` | `profile_info_state.dart` |
| `profile_overview_view_model.dart` | `profile_overview_state.dart` |
| `profile_tag_library_view_model.dart` | `profile_tag_library_state.dart` |
| `add_food_view_model.dart` | `add_food_state.dart` |
| `add_restaurant_view_model.dart` | `add_restaurant_state.dart` |
| `restaurant_search_view_model.dart` | `restaurant_search_state.dart` |
| `activity_upload_view_model.dart` | `activity_upload_state.dart` |

以下页面已完成业务 setState 清除：

- `profile_history_page.dart` — `ConsumerStatefulWidget` → `ConsumerWidget`
- `profile_tag_library_page.dart` — 同上
- `profile_info_page.dart` — 移除 7 个业务状态字段，保留 `_avatarPreviewBytes`
- `profile_page.dart` — `ConsumerStatefulWidget` → `ConsumerWidget`
- `add_food_page.dart` — 移除 `_isLoadingTags`, `_isSubmitting`
- `add_restaurant_page.dart` — 移除 `_isSubmitting`
- `restaurant_search_page.dart` — 移除全部业务状态字段

### Phase 5（部分）— Freezed abstract class 修复
- 所有 11 个 `@freezed class` 均已加上 `abstract` 关键字（Freezed 3.x + Dart 3.x 要求）
- 删除并重新生成了所有 `.g.dart` 文件（8 个 VM + 相关 state）
- 最后一次 `dart run build_runner build --delete-conflicting-outputs` 成功，无 codegen 错误

---

## 三、当前剩余错误（24 个）

### 错误 A — `foodie_map_page.dart`（11 个错误）

**原因：** `foodie_map_page.dart` 没有 import `foodie_map_state.dart`，导致 `FoodieMapPageState`、`FoodieMapFoodListState`、`FoodieMapFeedback`、`FoodieMapFeedbackKind` 找不到。

**修复：**
```dart
// 在 lib/features/foodie_map/presentation/pages/foodie_map_page.dart 顶部添加：
import 'package:eat_what_app/features/foodie_map/presentation/view_models/foodie_map_state.dart';
```

---

### 错误 B — `restaurant_search_page.dart`（1 个错误）

**原因：** 页面引用了 `RestaurantSearchState` 但没有 import `restaurant_search_state.dart`。

**修复：**
```dart
// 在 lib/features/upload/presentation/pages/restaurant_search_page.dart 顶部添加：
import 'package:eat_what_app/features/upload/presentation/view_models/restaurant_search_state.dart';
```

---

### 错误 C — `upload_page.dart`（5 个错误）

**原因：** 页面仍使用旧名称 `UploadPageFeedback` / `UploadPageFeedbackKind`，但新 state 文件中命名为 `ActivityUploadFeedback` / `ActivityUploadFeedbackKind`。

**文件：** `lib/features/upload/presentation/pages/upload_page.dart`
**涉及行：** 83, 831, 837, 838, 839

**修复：** 全文替换：
- `UploadPageFeedback` → `ActivityUploadFeedback`
- `UploadPageFeedbackKind` → `ActivityUploadFeedbackKind`

同时在文件顶部添加 import（如果缺少）：
```dart
import 'package:eat_what_app/features/upload/presentation/view_models/activity_upload_state.dart';
```

---

### 错误 D — `activity_upload_view_model.dart`（2 个错误）

**原因：** 第 43 行 `ProvinceResponse`、第 81 行 `CityResponse` 未 import。

**修复：** 在文件顶部添加：
```dart
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
```

---

### 错误 E — `add_food_view_model.dart`（2 个错误 + 1 个 warning）

**原因：**
1. 调用了 `ref.read(uploadRepositoryProvider).createFood(...)` 但 `UploadRepository` 没有 `createFood` 方法
2. `CreateFoodDto` 不是方法，应作为构造函数使用（实际类名为 `CreateFoodDTO`）

**正确流程（参考 `add_restaurant_view_model.dart` 已修复版本）：**
1. 先用 `imageUploadRepositoryProvider.uploadImages(images: images)` 上传图片，得到 `List<String>` keys
2. 创建 `CreateFoodDTO(restaurantId, name, ..., pictureUrl: uploadedKeys)`
3. 调用 `foodRepositoryProvider.uploadFood(dto)`（注意方法名是 `uploadFood` 不是 `createFood`）
4. 再调用 `foodRepositoryProvider.resolveCreatedFood(...)` 得到 `FoodVO?`

**相关文件：**
- `lib/shared/food/data/repositories/food_repository.dart` — 包含 `uploadFood(CreateFoodDTO)` 和 `resolveCreatedFood({...})`
- `lib/shared/food/data/models/create_food_dto.dart` — `CreateFoodDTO` 类定义
- `lib/features/upload/providers.dart` — `imageUploadRepositoryProvider`
- `lib/shared/food/providers.dart` — `foodRepositoryProvider`

同时删除不再需要的旧 import：
```dart
// 删除这行
import 'package:eat_what_app/features/upload/providers.dart'; // 不再需要 uploadRepositoryProvider
import 'package:eat_what_app/shared/food/data/models/create_food_dto.dart'; // 如果 DTO 换了名字
```

---

### 错误 F — `restaurant_search_view_model.dart`（3 个错误）

**原因 1：** `restaurantSearchHintDataSourceProvider` 不存在
`RestaurantSearchHintDataSource` 类在 `lib/features/upload/data/data_sources/restaurant_search_hint_data_source.dart` 中定义，但从未注册为 Riverpod provider。

**修复：** 在 `lib/features/upload/providers.dart` 中添加：
```dart
import 'package:eat_what_app/features/upload/data/data_sources/restaurant_search_hint_data_source.dart';

@Riverpod(keepAlive: true)
RestaurantSearchHintDataSource restaurantSearchHintDataSource(Ref ref) {
  return const RestaurantSearchHintDataSource();
}
```
然后重新运行 `build_runner` 生成 provider。

**原因 2：** `markIntroHintShown()` 方法在 `RestaurantSearchHintDataSource` 中不存在（只有 `shouldShowIntroHint()`）

**修复：** 在 `RestaurantSearchHintDataSource` 类中添加该方法：
```dart
Future<void> markIntroHintShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_howHintSeenKey, true);
}
```
或者将 ViewModel 中 `_dismissHint` 改为不调用 `markIntroHintShown`（提示已在 `shouldShowIntroHint` 中自动标记为已见）。

**原因 3：** `response.list` 不存在，`PaginatedData<Restaurant>` 的字段是 `.items`

**修复：**
```dart
// restaurant_search_view_model.dart 第 68 行
return response.list;  // ❌
return response.items; // ✅
```

---

## 四、修复顺序建议

```
# 1. 先修 import 类的简单错误（A、B、C、D）
# 2. 修 add_food_view_model（E）— 需要理解食物创建流程
# 3. 修 restaurant_search_view_model（F）— 需要添加 provider + 修 DataSource
# 4. 最后重跑 build_runner
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

## 五、尚未处理的 Phase 4（大文件拆分）

以下大文件可选拆分（不影响编译）：

| 文件 | 行数 | 建议提取 |
|---|---|---|
| `lib/features/profile/presentation/pages/profile_page.dart` | ~1000 | `_ProfileFoodCard`, `_ProfileHeaderSection` → `presentation/widgets/` |
| `lib/features/profile/presentation/pages/profile_info_page.dart` | ~1000 | 头像编辑、省市选择器 → `presentation/widgets/` |

---

## 六、关键架构说明

### Freezed 3.x 必须用 `abstract class`

```dart
// ❌ 旧写法（会报 "Missing concrete implementations" 错误）
@freezed
class FooState with _$FooState { ... }

// ✅ 正确写法
@freezed
abstract class FooState with _$FooState { ... }
```

### ViewModel 中允许返回值的方法

例如 `ProfileOverviewViewModel.loadMyFoods(page, size)` 返回 `Future<PaginatedData<FoodVO>>`——Notifier 可以有返回值，不一定每个方法都必须 setState。

### 页面状态监听模式

```dart
// build() 中响应式读取
final vmState = ref.watch(xxxViewModelProvider);

// 一次性副作用（toast、导航）
ref.listen(xxxViewModelProvider, (prev, next) {
  if (next.error != null && prev?.error != next.error) {
    AppErrorPresenter.showErrorToast(context, next.error!);
  }
});

// 触发动作（非响应式）
ref.read(xxxViewModelProvider.notifier).someMethod();
```

### Family Provider（按参数独立实例）

`ProfileHistoryViewModel` 用 `build(String targetType)` — 每个 targetType 独立 state：
```dart
ref.watch(profileHistoryViewModelProvider('restaurant'))
ref.watch(profileHistoryViewModelProvider('food'))
```

---

## 七、代码生成命令

```bash
# 全量重建（删除冲突输出）
dart run build_runner build --delete-conflicting-outputs

# 验证
flutter analyze
```

---

## 八、验收标准

- [ ] `flutter analyze` 无 error（warning 可接受）
- [ ] 所有 `@freezed` 类使用 `abstract class`
- [ ] 所有 ViewModel 继承 `_$XxxViewModel`（Notifier 模式）
- [ ] 页面 `build()` 中不出现业务状态的 `setState`
- [ ] `UploadRepository` 不含省市方法（已满足）
- [ ] `app_router.dart` 只包含路由定义（已满足）
