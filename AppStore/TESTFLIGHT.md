# TestFlight 上架清单(TESTFLIGHT.md)

只发 TestFlight 的**最快路径**,不追求公开 App Store 上架。一切就绪后 15 分钟能把 build 推上 TestFlight,30 分钟能拿到内部测试链接。

> 品牌:订算 / Subtally
> Bundle ID:`com.samxiao.SubscribeApp`(未改,避免重配 iCloud/App Group)
> Version:1.0(Build 1)

---

## 两条路径对比

| | 内部测试(Internal) | 外部测试(External) |
|---|---|---|
| 测试员上限 | 100(必须是你团队里的 App Store Connect 账号) | 10,000(任意邮箱,公开链接即加入) |
| 需要审核? | **不需要**,上传即分发 | 需要 Apple Beta App Review(首次 ~24h,后续 build ~1h) |
| 需要隐私政策 URL? | 否 | 是 |
| 需要 App 描述 / 截图? | 否 | 是(但比正式 App Store 简) |
| 适合 | 自己测、少量朋友 | 公开招测、Reddit/Twitter 招募 |

**建议首发走 Internal** — 把自己、朋友几个账号拉进去,跑一周稳定再走 External。

---

## 一次性准备(只做一次)

### 1. Apple Developer Program 付费 + 拿 Team ID
参考 [SIGNING.md](./SIGNING.md) §1–2。没付费账号的话先花 $99 入会,否则 Archive 上传会 403。

### 2. 写入 Team ID,重新生成工程

```bash
# 编辑 project.yml,把两处 DEVELOPMENT_TEAM: "" 改成你的 10 位 Team ID
cd /Users/samxiao/subsribe_app_done/SubscribeApp
xcodegen generate
```

### 3. Xcode 启用签名 + 勾 Capabilities

参考 [SIGNING.md](./SIGNING.md) §3–5,照做即可。对 TestFlight 来说只有下面几项是硬性:
- Automatic signing 勾上
- 主 target:iCloud (CloudKit)、App Groups、Push Notifications、Background Modes
- Widget target:App Groups

### 4. App Store Connect 里建 App

<https://appstoreconnect.apple.com> → My Apps → **+ New App**:

| 字段 | 值 |
|------|---|
| Platform | iOS |
| Name | `订算` |
| Primary Language | 简体中文 |
| Bundle ID | `com.samxiao.SubscribeApp`(下拉选,若没有,先去 Developer Portal 注册 App ID) |
| SKU | 任意,如 `subtally-ios-1` |
| User Access | Full Access |

**注:**若 Apple 提示 `订算` 重名,尝试备选:
- `订算 · 订阅管家`
- `Subtally · 订算`
- `订算 Pro`(但 "Pro" 会让审核更严)

英文 App Name 填 `Subtally`(若也重名:`Subtally App` / `Subtally for iOS`)。

---

## 每次发新 build(1 分钟)

### 1. Archive

Xcode 顶部 scheme 选 **SubscribeApp**,destination 选 **Any iOS Device (arm64)**:

```
Product → Archive
```

> 若菜单灰色:把 destination 换成真机或 "Any iOS Device (arm64)",Simulator 不能 Archive。

### 2. 上传

Archive 完成后 Organizer 弹出:
- 选最新 Archive → **Distribute App**
- Distribution method 选 **App Store Connect**
- Destination 选 **Upload**
- Signing:**Automatically manage signing** + 选你的 Team
- Next → Next → **Upload**

上传后 ASC 要 15-30 分钟处理 build(Processing…状态)。

### 3. TestFlight 分发

<https://appstoreconnect.apple.com> → 你的 App → **TestFlight** tab:

**走内部测试:**
1. Processing 完成后,build 左边会出现感叹号,提醒你填 **Export Compliance**(是否包含加密)。
   - 本 App 只用 HTTPS 的系统级加密 → 勾 **"Yes, we use encryption but only standard encryption built into the OS"** → 再勾 **"Qualifies for exemption"** → Save。
2. **Internal Testing** → 新建或选一个 group → **+ Testers** → 从你团队成员里勾选。
3. 选 build → **Start Testing**。测试员秒收 TestFlight App 邀请邮件。

**走外部测试(可选):**
1. 同样先填 Export Compliance。
2. **External Testing** → 建 group → **+ Testers**(填邮箱逐个或批量 CSV)。
3. 填下面这几个字段(这个是审核点):
   - **Beta App Description**:复制本目录 [description-zh.txt](./description-zh.txt) 前三段。
   - **Feedback Email**:能收信的邮箱。
   - **Marketing URL**(可选)
   - **Privacy Policy URL**:必须(见下节)。
   - **What to Test**:复制 [testflight-what-to-test.txt](./testflight-what-to-test.txt)。
4. **Submit for Beta Review**。首次审核约 24 小时,之后同一份 Beta Info 再发新 build 只需 ~1h。

---

## 需要你自己准备的两个 URL

### 隐私政策(外部测试必需)

最便宜的三种路线,任选:

1. **GitHub Pages**(推荐,免费,改动方便)
   - 建 repo `subtally-site`,放一个 `privacy.html`
   - 开 Pages → https://<你的用户名>.github.io/subtally-site/privacy.html
2. **Notion 公开页**(更快)
   - Notion 写好页,右上 Share → **Publish to web** → 拿到 public URL
3. **买域名 subtally.app**(最干净,~$15/yr,Cloudflare Pages 托管)

拿到 URL 后同步修改 [privacy-policy-url.txt](./privacy-policy-url.txt) 和 [support-url.txt](./support-url.txt)。

**内容建议**(隐私政策):
- 开门见山一句:"我们不采集任何个人信息。"
- 列本 App 用到的系统 API:iCloud (CloudKit 私有数据库)、本地通知、相机 (OCR)、相册 (选图 OCR)。
- 列不做的事:不接分析 SDK、不传数据到自有服务器、不卖数据、不投广告。
- 列用户的控制权:在 iCloud 设置里可随时停用同步;删 App 即清除所有本地数据。
- 联系邮箱。

### Support URL

同上。若只做内测可用你的邮箱 `mailto:` 链接代替,但 External 审核要 https:// 的页面。

---

## TestFlight 发给测试员的话(模板)

中文:
```
你好,感谢参加「订算」的封闭测试 🙏

订算是我最近做的一款订阅管理 App,主打:
- 一屏看完所有订阅账单
- 试用到期前锁屏倒计时
- iCloud 同步,不上云不采集

安装步骤:
1. iOS 上先装 TestFlight(App Store 里搜):
   https://apps.apple.com/app/testflight/id899247664
2. 点击这个邀请链接:<TestFlight 会生成的 8 位码>
3. 在 TestFlight 里点「安装」即可

已知限制:
- 仅 iOS 17+,iPadOS 同步
- Live Activity 需要真机(模拟器不渲染动效)
- 数据落地个人 iCloud,换设备登同一个 Apple ID 即可

反馈请发到 <你的邮箱>,或在 TestFlight 里「Send Beta Feedback」。
```

---

## 前置 checklist

- [ ] 付费 Apple Developer Program 成员
- [ ] Team ID 填进 `project.yml`(两处)
- [ ] `xcodegen generate` 跑过
- [ ] Xcode 里 Signing & Capabilities 都绿勾
- [ ] App Store Connect 里 App 已创建,名字不冲突
- [ ] `Archive` → `Upload` 成功,ASC 里看到 Processing 完成的 build
- [ ] Export Compliance 勾过
- [ ] 内部测试员邮箱/账号已加入
- [ ] (可选,外部)隐私政策 URL 可访问
