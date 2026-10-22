# 原型

「沙软今天吃什么」的界面设计，取自 Claude Design 上两个工程的最新发布版（2026-10-22）。

| 目录 | 内容 | 在线版 |
| --- | --- | --- |
| `design-system/` | 舞台设计规范。`README.md` 是总规则；`tokens.json` 是颜色、字体、间距、圆角、阴影、动效令牌；`components/<Name>/` 是组件说明（`README.md`）与预览（`preview.html`）；`assets/<Group>/README.md` 是各组资源的说明 | [舞台设计规范](https://claude.ai/artifact/6Hpr9PXH5f9Db7YC7ubjH4) |
| `screens/` | 画布「G 定稿」页的 62 张画板；`canvas.json` 记录画板标题与排布 | [风格候选](https://claude.ai/artifact/1cGfzwxyrkovZSZkA5ftqG) |
| `assets/` | 菜品插画（`dishes/*.svg`）、实拍示例图（`photos/*.png`）和界面图标（`icons/*.svg`，MingCute Line，按用途命名，对照表见 `design-system/assets/Icons/README.md`） | |

## 画板

**主页面、详情与发布**

| 文件 | 页面 |
| --- | --- |
| `G2-Home.dc.html` | 发现 |
| `G-HomePhoto.dc.html` | 发现（实拍图版） |
| `G-HomeTopic.dc.html` | 发现，选中专题 |
| `G-Nearby.dc.html` | 附近（含排序菜单） |
| `G-NearbySearch.dc.html` | 附近，搜索结果和已筛选 |
| `G-Me.dc.html` | 我的 |
| `G-MeFav.dc.html` | 我的，收藏（菜、店） |
| `G-MeComments.dc.html` | 我的，评论 |
| `G-Inbox.dc.html` | 消息 |
| `G-Dish.dc.html` | 菜品详情 |
| `G-DishMore.dc.html` | 菜品详情往下滑（上传者、吃过的人说） |
| `G-Detail.dc.html` | 餐厅详情 |
| `G-DetailMore.dc.html` | 餐厅详情往下滑（你觉得这家怎么样、全部菜品、信息有误） |
| `G-PickShop.dc.html` | 发布 1/2 · 选店 |
| `G-AddDish.dc.html` | 发布 2/2 · 加菜（整页长图，390×1160） |
| `G-AddDishEmpty.dc.html` | 发布 2/2，还没加照片 |
| `G-Crop.dc.html` | 发布 · 调整照片 |
| `G-Login.dc.html` | 登录 |
| `G-Nav.dc.html` | 底部导航（发现、附近、我的共用） |
| `G-Kit.dc.html` | 组件表 |
| `G-PhotoPipeline.dc.html` | 实拍图从上传到上舞台的处理流程 |

**登录与认证**

| 文件 | 页面 |
| --- | --- |
| `G-PhoneLogin.dc.html` | 手机号登录 |
| `G-PasswordLogin.dc.html` | 密码登录（可切换出错提示） |
| `G-Verify.dc.html` | 学生认证（注册后 / 设置里，未认证 / 已认证） |

**底部面板**

| 文件 | 页面 |
| --- | --- |
| `G-PanelPlace.dc.html` | 地点和饭点 |
| `G-PanelFilter.dc.html` | 附近筛选 |
| `G-PanelTag.dc.html` | 加标签（口味标签和我的标签） |
| `G-PanelReport.dc.html` | 举报 |

**搜索、专题、评论与店**

| 文件 | 页面 |
| --- | --- |
| `G-Search.dc.html` | 搜索（没输入 / 有结果 / 没找到） |
| `G-TopicArchive.dc.html` | 往期专题 |
| `G-Topic.dc.html` | 专题 |
| `G-Comments.dc.html` | 全部评论 |
| `G-WriteComment.dc.html` | 写评论、回复 |
| `G-NewShop.dc.html` | 新建店（地图选点、同名提示） |
| `G-WrongInfo.dc.html` | 信息有误 |

**他人主页与我的子页**

| 文件 | 页面 |
| --- | --- |
| `G-UserProfile.dc.html` | 他人主页 |
| `G-Follows.dc.html` | 粉丝与关注（含对方没有公开） |
| `G-EditProfile.dc.html` | 编辑资料 |
| `G-MyTags.dc.html` | 我的标签 |
| `G-TagDishes.dc.html` | 标签下的菜 |
| `G-History.dc.html` | 足迹 |

**设置**

| 文件 | 页面 |
| --- | --- |
| `G-Settings.dc.html` | 设置（含退出登录确认） |
| `G-SettingsAccount.dc.html` | 账号与安全 |
| `G-Devices.dc.html` | 登录设备 |
| `G-DeleteAccount.dc.html` | 注销账号 |
| `G-SettingsPrivacy.dc.html` | 隐私 |
| `G-Blocked.dc.html` | 屏蔽的人 |
| `G-SettingsNotify.dc.html` | 通知 |
| `G-SettingsAbout.dc.html` | 关于 |
| `G-Feedback.dc.html` | 反馈 |

**版本、维护、公告与提示**

| 文件 | 页面 |
| --- | --- |
| `G-ForceUpdate.dc.html` | 强制更新 |
| `G-UpdatePrompt.dc.html` | 建议更新 |
| `G-Maintenance.dc.html` | 停服维护 |
| `G-HomeNotice.dc.html` | 发现，带公告条 |
| `G-AnnounceDialog.dc.html` | 重要公告 |
| `G-Captcha.dc.html` | 人机验证（可切换验证码太频繁） |
| `G-PanelOff.dc.html` | 功能暂时关了（可切换维护中只读） |
| `G-PanelLimited.dc.html` | 操作受限（可切换封禁中、未认证拦截） |

**宽屏**

| 文件 | 页面 |
| --- | --- |
| `G-WideHome.dc.html` | 宽屏发现，1280×800，舞台铺满加左侧面板 |
| `G-WideNearby.dc.html` | 宽屏附近，1280×800，地图铺满加左侧面板 |

**图标**

| 文件 | 页面 |
| --- | --- |
| `G-Icons.dc.html` | 图标表 |
| `G-Icon.dc.html` | 图标组件，其他画板用 `<dc-import name="G-Icon" icon="search" size="22">` 引入 |

## 阅读方式

- `.dc.html` 依赖 Claude Design 的运行时（`support.js`、`<dc-import>`、`<sc-for>`、`<sc-if>`、`{{…}}` 绑定），本地直接打开只能看到静态标记和样式。看交互、动效请打开在线版。
- 读源码时，结构和样式看 HTML 与内联 CSS，交互逻辑看文件末尾 `<script type="text/x-dc">` 里继承 `DCLogic` 的类。
- `G-Nav.dc.html` 由发现、发现（实拍图版）、附近、我的通过 `<dc-import name="G-Nav">` 引入；底部面板和带状态的画板（如 `G-HomeTopic`、`G-MeFav`）用 `<dc-import>` 引入原页面，垫在下面或传入状态；图标统一通过 `G-Icon` 引入，`icon` 属性就是 `assets/icons/` 里的文件名（驼峰写法，如 `chevronRight` 对应 `chevron-right.svg`）。其他画板之间只用 `href` 互相跳转。
- 有些画板在右侧面板里有切换项（Tweaks），用来看同一页的不同状态，比如密码登录的出错提示、认证的已认证状态。
- 组件预览 `preview.html` 用的是 `tokens.json` 注入的 CSS 变量（如 `var(--ink)`），同样要在在线版里看。
- 在线版里的 `/_blob/<id>` 资源引用已改写为指向 `assets/` 的相对路径，其余内容与发布版一致。`design-system/design-system.json` 的 `blob` 字段仍是在线版的资源 ID。
- 第一轮、第二轮的风格候选（A–I）只保留在在线画布里，没有收进仓库。

## 更新

设计以在线版为准。在线版改过之后，重新导出覆盖本目录，并按上面的规则改写资源路径。
