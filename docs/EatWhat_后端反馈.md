# EatWhat 客户端对后端的反馈（2026-11-02）

客户端把阶段一到五的实现和后端对照了一遍。客户端直接按后端最新源码（分支 `fix/legacy-it-repairs-y7h311`，含未部署的部分）的契约实现，不为已部署版本做兼容。下面是需要后端处理或确认的事项，行号按该分支。

## 1. 要修的问题

| # | 问题 | 位置 | 影响 | 建议 |
| --- | --- | --- | --- | --- |
| 1 | `/user/userInfo` 的 `earnedLikes` 只累加 `activity_foods`、`activity_dinners`、`activity_posts` 三张表的 `likes_count`，没有算 `foods.likes_count` | `mapper/UserMapper.java:88-94`（已部署版本相同） | 「我的」和他人主页的「获赞」对新用户一直是 0 | 加上 `foods` 表里自己上传、未删除的菜的赞数 |

## 2. 接口设计上希望调整的地方

| # | 现状 | 对客户端的影响 | 建议 |
| --- | --- | --- | --- |
| 2 | 菜品图 `pictureUrl` 和头像 `avatar` 是有效期 600 秒的预签名地址（按 `application.example.yml` 的 `sign-get-ttl-seconds`），`foods/` 不是公开读前缀 | 每次请求签名都不同，客户端缓存的数据 10 分钟后图片就打不开。客户端已改为用去掉查询串的地址做图片缓存的 key，没下载过的旧地址仍然会失效 | 已审核公开的图走公开读前缀或 CDN 的稳定地址；做不到的话，把有效期延长到小时级 |
| 3 | 新源码里，未通过审核的图会从 `pictureKeys` 和 `pictureUrl` 中一起滤掉；联调约定还写明两者不保证逐项对应 | 原封面（第一张图）被滤掉后，两个列表都从原来的第二张开始，客户端看不出封面没了，`coverCrop` 和舞台色会套到别的图上。客户端现在只能在两个列表张数不同时放弃裁切 | 封面被滤掉时把 `coverCrop` 置空，或者返回封面是否可见的标记；最好再返回 `[{key, url}]` 这样逐项对应的结构 |
| 4 | 20006 `DATA_SYNC_PENDING` 一码多用：注册或登录等待协调、目录冲突，赞、收藏、标签、菜品详情、发布都会返回 | 客户端分不清哪些可以退避重试、哪些已经受理、哪些要重新读取，现在只能统一提示「数据正在同步，请稍后再试」 | 在 `data` 里带上 `retryable`、`retryAfterSeconds`，或者按场景拆成几个码 |
| 5 | 同名店查重靠 `/restaurant/search` 的 `LIKE '%name%'`，不忽略空白 | 「麻辣 烫」和「麻辣烫」互相查不到。客户端现在用原名和去掉空白的名字各搜一次 | 在服务端做名称规范化比较，或者提供专门的查重接口 |
| 6 | `/foods/recommend` 实际返回数组，接口文档写的是分页对象 | 后端已确认不改返回格式 | 请修正 OpenAPI，客户端同步后删掉兼容分支 |
| 7 | 联调约定写 `/user/info` 的 `banUntil` 是 ISO-8601 Instant，但 `JacksonConfig` 把 `Instant` 序列化成毫秒 | 客户端按源码的实际输出解析毫秒 | 把联调约定改成 Unix 毫秒 |
| 8 | 受限会话没有放行足迹、粉丝和关注列表、取消赞、取消收藏、取消关注、`/foods/my`、`/foods/favorites`、`/foods/tags/my`（反馈、信息有误、举报已在 `81e4cad` 放行） | 客户端已按后端范围拦截，产品文档 7.2 也跟着改了 | 这几项如果是有意不放行，请确认；尤其是取消赞和取消收藏，封禁后自己的记录撤不掉 |
| 9 | 完整源码契约 `business-openapi.yaml` 里没有评论接口（`/foods/{foodId}/comments`、`/comments/*`、`/foods/{foodId}/gallery`），因为评论控制器带 `@ConditionalOnProperty`，生成时没有注册 | 客户端已经把这个文件当作接口依据，契约测试只能先把评论接口列为豁免 | 生成契约时打开评论相关的配置开关，或者在描述里标明注册条件 |
| 10 | `POST /feedback/messages` 只收 `text`、`screenshotKeys`、`context`，没有版本、补丁号和设备型号；服务端也不从请求头记录这些 | 产品要求反馈自动带上版本、补丁号和设备型号，便于排查。客户端现在只在反馈页写出版本和补丁号，请用户自己写进内容 | 加上 `appVersion`、`patchNumber`、`deviceModel`、`platform` 这几个选填字段，或者从约定的请求头里记录 |
| 11 | `/foods/list` 返回的菜没有 `hubName`、`hubId`，`FoodService.toVO` 没有设置这两个字段；进度说明里写的是菜品列表已带 `hubName` | 搜菜结果显示不了商圈名 | 在 `toVO` 里补上 |
| 12 | 店铺的招牌菜摘要 `RestaurantFoodSummary` 没有封面取景 `coverCrop` | 店铺舞台上的招牌菜盘子只能居中裁切，和菜品详情不一致 | 在摘要里补上 `coverCrop` |
| 13 | `/notification/cards` 没有「全部已读」接口，`/notification/read/all` 只标记旧通知表 | 客户端只能先调旧接口，再对已加载的未读卡片逐条调 `/cards/{id}/read`；没加载到的卡片点了「全部已读」后仍是未读 | 提供 `POST /notification/cards/read-all`，可按分栏 |
| 14 | 通知卡片没有目标的名称和缩略图（菜名、菜的封面） | 消息里写不出菜名，只能写「你上传的菜」，右边不放缩略图 | 卡片里带上目标的名称和封面地址 |
| 15 | 反馈结果卡片（`CaseDetail`）里没有相关的店或菜 | 产品要求反馈结果点了跳到相关的店或菜，现在做不到 | 带上目标类型和 id |
| 16 | 专题详情里的菜不返回 `pictureKeys` | 封面被审核滤掉时，客户端识别不出来，裁切会套到第二张图上 | 和菜品详情一样返回 `pictureKeys` |
| 17 | 往期专题列表只有摘要，不带菜图 | 客户端要逐个请求专题详情才能显示每期的菜图 | 摘要里带前几道菜的封面 |
| 18 | 公开评论没有作者 id、头像、「我赞过没有」、回复条数 | 判断是不是自己的评论只能对照「我的评论」最近 100 条，更早的评论不显示「删除」；赞的状态要每条评论单独查一次，回复不查，赞过的回复显示成没赞 | 公开评论返回作者 id、头像、`likedByMe`、回复条数 |
| 19 | `GET /comments/{commentId}/replies` 只能按时间倒序 | 产品要求评论下露出最早的 2 条回复，客户端只能在第一页里自己排，回复超过 20 条时露出的不一定是最早的 | 支持按时间正序 |
| 20 | 评论图片的签名地址只有 30 秒有效 | 在列表里停留稍久后再滑到的图会加载失败 | 和菜品图一致，或者走公开读的稳定地址 |
| 21 | `GET /foods/{foodId}/gallery` 不带拍摄者 | 大图里标不出评论照片是谁拍的，只能从已加载的评论里找 | 每张图带上作者的昵称和 id |
| 22 | 通知卡片定义了 `CommentDetail`（`foodId`、`commentId`、`replyId`），但没有任何地方生成评论和回复的消息，`COMMENTS` 分栏也没有数据来源 | 评论、回复的消息收不到；客户端按 `kind` 为 `comment`、`reply` 实现了跳转，取值未经确认 | 补上评论、回复、评论被赞的消息来源，并在契约里写明 `kind` 的取值 |
| 23 | Apifox 业务模块的接口文档还是 `user-blocks-consent-20261026`，客户端在用的 37 个接口不在里面（评论、专题、消息卡片、反馈、店铺评价和收藏、登录设备、推送开关、换绑手机等） | 客户端从 Apifox 同步接口文档，现在同步会让契约测试失败，只能先保留手里的完整源码契约 | 把按当前源码生成的完整契约（`business-openapi.yaml`）更新到 Apifox |

## 3. 统一认证回跳

客户端用 App Links（Android）和 Universal Links（iOS）接收 `https://eat.v50to.you/app/auth/callback?result=..&code=..`。域名从 `v50to.you` 改成了 `eat.v50to.you`，需要后端做两件事。

**改 App 的回跳地址。** 把 `app.oauth-app-success-redirect`（环境变量 `APP_OAUTH_APP_SUCCESS_REDIRECT`）设成 `https://eat.v50to.you/app/auth/callback`。现在的默认值是 `https://v50to.you/app/auth/callback`（`AuthService.java:112`、`application.example.yml:120`），客户端已经不认这个域名，回跳会停在浏览器里。

**在 `eat.v50to.you` 上放两份校验文件。** 系统只到链接所在的主机名取文件，放在根域名 `v50to.you` 上不起作用。两份文件的要求：

- 走 HTTPS，返回 200；
- `Content-Type: application/json`；
- 不能有重定向；
- `/.well-known/` 不能被 SPA 的兜底页接走；
- Apple 经自己的 CDN（`app-site-association.cdn-apple.com`）取文件，境外要能访问到。

`https://eat.v50to.you/.well-known/assetlinks.json`：

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "you.v50to.eat",
    "sha256_cert_fingerprints": [
      "DC:93:FE:AD:DD:6F:85:D3:EA:0E:B8:A2:61:6E:CB:04:59:6E:39:82:EB:02:96:D6:03:8D:CF:AC:AF:40:47:4B"
    ]
  }
}]
```

指纹是上传密钥（别名 `upload`）的。以后上了会重签名的商店，客户端再提供商店证书的指纹，加进数组。

`https://eat.v50to.you/.well-known/apple-app-site-association`（不带扩展名）：

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["VX6R92VA32.you.v50to.eat"],
      "components": [{ "/": "/app/auth/callback" }]
    }]
  }
}
```

**Web 的回跳地址。** `client=web` 时，后端跳回 `app.oauth-success-redirect`。线上看起来没有配置这一项，默认值是 `/home?result=..&code=..`（`AuthService.java:109`），而 Flutter Web 没有 `/home` 这个路径，会显示「页面不存在」。请把 `APP_OAUTH_SUCCESS_REDIRECT` 设成 `https://<Web 域名>/app/auth/callback`，客户端已经有这条路由，不用再改。

## 4. 客户端已按未部署源码编码的部分

客户端已经按新源码改了下面这些，不兼容已部署版本。联调前需要先部署；部署后请更新 `business-deployment-status.json` 和线上 OpenAPI：

- 跨站同步同意：客户端不再自动代用户同意，改成由用户在面板里点同意；会话中遇到 20005、20009 时弹出同一个面板，grant 返回 20007、20008 时让用户重新登录。新号码不带同意注册时，后端先核销验证码再返回不带 proof 的 20005，用户同意后要重新收一次验证码。能否改成先检查同意、再核销验证码，或者在这种情况下也返回 proof？`/auth/consent/offer-with-password` 客户端暂时没接。
- 发布菜品和新建店返回 `moderationStatus`，带 `Idempotency-Key` 请求头（UUID，同一份草稿重试时沿用）。待审核的菜不在 `/foods/my` 里，只在 `/moderation/submissions/my` 里，客户端暂时没做这个列表。
- `/restaurant/search`、`/restaurant/browse` 带 `campusId`。搜索页改用 `/restaurant/browse`。
- 店铺的 `signatureFoods`、`visibleFoodCount`、`publicTastes`、`priceBand`、`recommendationRate`、`ratingCount`，以及营业状态。
- 菜名、标签、店名的长度按 code point 计，标签上限 10。

## 5. 其他

- 统计埋点：客户端决定用后端自建的 `/telemetry`（带同意管理），崩溃仍用 Sentry。请确认 `/telemetry` 的部署时间和事件格式是否稳定。
- 推荐的已推荐集合按「用户、校区、分类、日期」记录。客户端的转盘和「今日推荐」共用同一个集合，这个行为我们接受，不需要改。
