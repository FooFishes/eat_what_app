# 分享落地页

分享链接（`/dishes/<id>`、`/shops/<id>`、`/topics/<id>`）在没装 App、或系统没把链接交给 App 时，浏览器打开的轻量页面。Flutter Web 不上线（2026-11-21），这里是单文件静态页，不走构建，不依赖 CDN。

页面按路径调游客可用的公开接口，照 App 的菜品详情、餐厅详情和专题页画出预览（菜和店是舞台 + 抽屉，专题是白底页），底部是「在 App 中打开查看」和「下载 App」。主数据接口失败或路径不认识时显示通用介绍，评论、图集、菜单等次要数据失败时不显示那一块。赞、收藏、写评论、导航、点进别的菜或店等要 App 的操作都弹一个底部面板，引导打开或下载 App；分享用系统分享或复制链接，照片可以在页面里左右翻看。

## 文件

- `index.html`：页面本身，CSS 和 JS 都内联。
- `icon-192.png`：横幅和 favicon 用的 App 图标，复制自 `web/icons/Icon-192.png`。

## 部署

需要两个主机名，部署同一份文件：

| 常量 | 是什么 |
| --- | --- |
| `SHARE_HOST` | 分享链接所在的主机名，落地页的正常入口 |
| `OPEN_HOST` | 第二个主机名（如 `open.<域名>`），「打开 App」链接指向这里 |

必须配 `OPEN_HOST`：iOS 在 Safari 里点同一主机名的链接不会触发 Universal Links，只有跨主机名才会交给 App。`OPEN_HOST` 留空时页面退回当前主机名，只是占位，多半唤不起 App。

两个主机名上都这样配：

- `index.html` 和 `icon-192.png` 放在站点根目录。
- `/dishes/*`、`/shops/*`、`/topics/*` 回落到 `/index.html`（不重定向，地址栏保持原路径）。
- `/.well-known/` 和 `/api` 不回落：`/.well-known/apple-app-site-association`、`/.well-known/assetlinks.json` 原样返回（AASA 用 `application/json`，不能重定向），`/api` 反代到业务后端。

nginx 示例：

```nginx
location /api/ { proxy_pass http://backend; }
location /.well-known/ { default_type application/json; }
location ~ ^/(dishes|shops|topics)/ { try_files $uri /index.html; }
```

## 可配置常量

都在 `index.html` 的 `<script>` 开头：

| 常量 | 默认 | 说明 |
| --- | --- | --- |
| `API_BASE` | `/api` | 业务接口前缀 |
| `SHARE_HOST` | 空 | 分享链接的主机名 |
| `OPEN_HOST` | 空 | 唤起用的第二个主机名；页面在它上面打开时说明系统没交给 App，改成以「下载 App」为主，不再链回自己 |
| `DOWNLOAD_URL_ANDROID`、`DOWNLOAD_URL_IOS` | 空 | 下载地址；为空时「下载 App」显示「待接入」且不可点 |
| `ANDROID_PACKAGE` | `you.v50to.eat` | 安卓包名 |

## 唤起方式

- iOS：「打开 App」是指向 `https://{OPEN_HOST}{路径}{参数}` 的普通链接，由 Universal Links 交给 App；没装时 Safari 打开 `OPEN_HOST` 上的本页，显示「没有找到 App，可以先下载」。
- 安卓：`intent://{OPEN_HOST}{路径}#Intent;scheme=https;package=you.v50to.eat;S.browser_fallback_url=…;end`，走 App Links 的 https intent-filter；没装时打开下载地址，没有下载地址就打开 `OPEN_HOST` 上的本页。
- 微信、QQ 内置浏览器：不尝试唤起，蒙层提示「点右上角，选择在浏览器打开」。
- 电脑上：提示在手机上打开。

## App 端待做

落地页能唤起 App 之前，App 和服务器还要做这些（见技术架构 6.2、6.3）：

- 安卓清单：给 `SHARE_HOST` 和 `OPEN_HOST` 的 `/dishes`、`/shops`、`/topics` 加带 `autoVerify` 的 https intent-filter。
- iOS：Associated Domains 加 `applinks:<SHARE_HOST>` 和 `applinks:<OPEN_HOST>`，更新 `Runner.entitlements`。
- 两个主机名下都放 `/.well-known/apple-app-site-association` 和 `/.well-known/assetlinks.json`。
- `DeepLinkHandler` 的白名单接受这两个主机名，并加上三条分享路径。

## 本地预览

页面要求从站点根目录访问（图标用绝对路径 `/icon-192.png`），需要一个能把分享路径回落到 `index.html` 的静态服务器；没有 `/api` 时显示通用介绍。

## 署名

页面内联了 MingCute 图标（Apache License 2.0，见 `assets/LICENSE-MingCute.txt`）和 Twemoji 的评论表情回应（CC BY 4.0，见 `assets/emoji/LICENSE-Twemoji.txt`）。
