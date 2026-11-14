# EatWhat 设备标识与风控

> 2026-11-14 方案稿，还没有落代码。只写客户端这一端，对服务端只说客户端会发什么、需要什么，不替它设计。后端只需要看第 2 节。确认后把实现拆进技术架构（第 3、9.1、9.4、19.1、20 节）和依赖选型，接口由后端定了再同步 OpenAPI。

## 1. 结论

- 一台设备由两类信息描述：客户端自报的**设备信息**（标识和档案），平台签发、服务端验签的**证据**。前者只能当线索，信任只由后者派生，而且派生是服务端的事。
- 设备只通过一个接口自报：设备注册。它既接受游客调用，也接受带鉴权头的登录态调用；带鉴权头时服务端据此把设备和账号关联起来。
- 不加任何自定义请求头，不改现有的登录和注册账号接口。横切的只有已有的鉴权头。
- 游客是「注册过设备、没有令牌」的状态，不发匿名账号。
- 证据现在一个渠道都不接（Play Integrity 已定不接），只立抽象，以后加渠道是加一个实现。

## 2. 给后端

这一节自包含，说明客户端会发什么、什么时候发、需要服务端提供什么。接口形状是客户端的提议，照现有接口的习惯写（资源名复数、camelCase、`Result` 外壳）；后端可以改名改形，定了同步 OpenAPI。

### 2.1 设备注册 `POST /devices`

只有这一个接口承载设备信息。鉴权头可选：

- 不带 `satoken`：游客态注册。时机是用户同意隐私政策之后（登录页勾选或首启弹窗都算）。
- 带 `satoken`：登录态注册，和其他已登录请求一样。时机是每次登录成功之后，服务端据此知道「这台设备上登录了这个账号」。登录接口本身不改。

两种调用请求体相同。同一 `installId` 重复提交按更新处理。客户端在档案变了（App 版本、系统版本）时重发；失败静默，下次冷启动重试。

```json
{
  "installId": "019365a0-7c3e-7d2a-9f1b-3e8c2a4d5f60",
  "hardwareId": "a3f9c2e1d4b5a6f7",
  "platform": "android",
  "model": "Pixel 8",
  "osVersion": "14",
  "appVersion": "1.2.3",
  "buildNumber": 62,
  "patchNumber": 3,
  "screenWidth": 1080,
  "screenHeight": 2400,
  "pixelRatio": 2.625
}
```

- `installId`：UUID v7，首次启动生成，存 Keychain / Keystore；卸载重装后 iOS 大概率不变、Android 会变，Web 存 localStorage 可被清。三端统一的键，必填。
- `hardwareId`：Android 的 ANDROID_ID（按签名和用户隔离，卸载重装不变）、iOS 的 `identifierForVendor`（同厂商 App 全部卸载后才变）、Web 为 null。
- `platform`：`android` / `ios` / `web`，必填。
- `model`、`osVersion`：Web 取不到时为 null，不编。
- `appVersion`、`buildNumber`：来自 `pubspec.yaml` 的版本名和构建号；`patchNumber` 是 Shorebird 补丁号，没有补丁为 null。
- `screenWidth`、`screenHeight`：逻辑像素；`pixelRatio`：设备像素比。

响应 `ResultVoid`，客户端不需要返回值。

### 2.2 登录设备列表 `GET /auth/sessions`

`DeviceSession` 加两个字段，`device` 保留：

- `deviceName`：能显示给用户看的名字，如「Pixel 8」「iPhone 15 Pro」「Chrome」，由服务端从注册的档案拼，客户端不再自己拼。
- `lastActiveAt`：最近活跃时间，`date-time`。

### 2.3 埋点 `POST /telemetry/events`

- 去掉「需登录」，游客也能上报。
- `Event.properties` 里固定带 `installId`；游客期间 `userId` 为空。结构不变。

### 2.4 证据（预留，现在不会带）

接入渠道时，发验证码、登录、注册账号的请求体加一个可选字段，不用请求头：

```json
{ "attestation": { "provider": "app-attest", "token": "..." } }
```

`provider` 是开放集合，服务端只验自己接了的渠道。渠道需要的 challenge 接口、验签方式接的时候再定。

### 2.5 客户端不做的

- 不判断设备可信与否，不传任何「我可信」的字段，不做风控拦截。
- 不加自定义请求头，不在设备注册以外的请求里带设备信息。
- 不发 IDFA，不接 OAID。

## 3. 客户端实现

- **标识**：`uuid` 包生成 v7，存安全存储。iOS 首次启动清 Keychain 残留的登录态时不清安装 ID（技术架构第 20 节）。Android 的安全存储排除出自动备份，Keystore 密钥不随备份走。读安全存储失败就重新生成并记一次面包屑，不阻断启动。生成不等于采集，只在有同意记录后才发出去。
- **档案与硬件标识**：`device_info_plus`（型号、系统版本、IDFV）和 `android_id`，依赖选型里前者从「暂不引入」改为引入，后者和 `uuid` 一起加进总表。
- **注册**：两个触发点。同意记录写入后（技术架构 9.4，启动流程第 8 步，和 Sentry、埋点并列）注册一次；登录成功后（`sessionProvider` 进入已登录）带鉴权头再注册一次。上次成功注册的档案摘要和登录用户 id 存 `prefs.*`，档案没变、同一用户已注册过就不重发。首帧不等它。退出登录不注销设备，设备级数据留着。
- **证据抽象**：`AttestationProvider` 是一个渠道，三件事：`id` 渠道名；`isAvailable()`；`attest(challenge)` 返回 `Attestation(provider, token)` 或 null，`challenge` 可选，渠道私有的登记步骤收在实现里。`DeviceAttestation` 门面按平台持有一组 provider，问第一个可用的，都不可用返回 null。第一步只有空实现。渠道实现以后多半是自写本地插件（Pigeon，参照 `packages/eat_baidu_map/`）。候选渠道：App Attest、华为 Safety Detect、国内风控厂商 SDK。
- **游客**：埋点照常采集并带安装 ID，前提是 `/telemetry` 放开登录；放开前维持 19.1「游客不采集」。游客登录后的那次注册把设备和账号关联起来，客户端不做迁移。
- **代码位置**：`core/platform/device/`（`DeviceIdentity`、`DeviceProfile`、`AttestationProvider`、`DeviceAttestation`，条件导入拆 `_io` / `_web`）；`data/device/` 注册接口类；`state/device.dart` 暴露标识和档案、负责两个触发点，监听同意记录和 `sessionProvider`。`core/network` 和 `data/auth/` 不改。标识生成与容错、注册触发条件写单元测试，接口用假实现。

## 4. 隐私

- 随机 ID 和硬件标识都算设备标识，产品 7.6 已写明用途，游客段也列了设备信息，隐私政策文案不用改。
- 只在同意后发送，和其他 SDK 的初始化门一致。
- App Store 隐私标签勾 Device ID（用了 IDFV）；不用 IDFA，不触发 ATT。
- 证据渠道接入时才列进依赖选型第 17 节的第三方清单。

## 5. 分阶段

1. 客户端：安装 ID、硬件标识、档案（含型号）、两个触发点的注册逻辑。注册接口上线前只到本地准备好。
2. 后端放开游客埋点、设备列表给设备名后：游客开始采集，列表改用服务端的名字。
3. 证据渠道暂不定，出现刷量迹象或准备上商店前再从第 3 节的候选里选第一个接。

已定（2026-11-14）：型号随档案上报，给登录设备列表显示用；证据渠道不预选；不加自定义请求头，不改登录接口。
