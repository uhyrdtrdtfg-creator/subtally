# 订算 Subtally

> 原生 iOS 订阅管理 App。让每一笔订阅都看得清、管得住。
>
> A native iOS subscription manager — see every subscription, cut every leak.

**品牌:** 订算 / Subtally
**平台:** iPhone (iOS 17+)
**栈:** SwiftUI · SwiftData · CloudKit · WidgetKit · ActivityKit · App Intents · Vision
**状态:** 1.0 · 准备 TestFlight

---

## 功能概览

| 模块 | 能力 |
|------|------|
| **数据** | 60 种币种 · 实时汇率 (open.er-api.com · 6h 刷新) · 本地 + iCloud 私有数据库同步 |
| **提醒** | 到期前 2 天 + 当日本地通知 · 试用期倒计时 Live Activity + 灵动岛 |
| **桌面** | Upcoming / MonthlyTotal 两种 Widget · 小/中/锁屏矩形/锁屏圆形四规格 |
| **自动化** | Webhook(HMAC-SHA256 签名、重试退避、Slack/Discord/Bark/Telegram 预设)· App Intents (Siri / Shortcuts 4 个意图) |
| **导入** | Vision OCR 扫描支付凭证,50+ 服务模板库 |
| **分账** | 家庭/室友共担,按 shares 分比例记账 |
| **洞察** | 6 条规则引擎:重复分类、年付节省、Top 集中度、试用累计、USD 占比、健康 |
| **分享** | ImageRenderer 生成 1080×1920 年度分享卡片 · ShareLink 多渠道 |
| **后台** | BGAppRefreshTask 每 4h 刷汇率 + 扫 webhook 事件 · 首启 App Group 共享存储预热 |

## 技术亮点

- **CloudKit 冲突自动合并** — 用 SwiftData `@Model` 避免手写 `CKRecord`,所有属性带默认值满足 CloudKit 约束
- **Widget 数据共享** — `App Group (group.com.samxiao.SubscribeApp)` 让 Widget target 直接读主 App 的 SwiftData store
- **Webhook 模板引擎** — Mustache 风格 `{{var}}`,22 个变量含中文友好版本,body 模板按 Content-Type 用户自定义
- **多币种换算** — `AppGroup.convert(amount, from:, to:)` 以 USD 为枢轴,60 种 ISO 4217 内置 fallback
- **价格历史** — 保存时自动 diff,`PriceChange` SwiftData 模型 + Charts 折线图
- **Live Activity** — 试用 48h 内自动触发锁屏倒计时,App 启动时 `TrialActivityManager` 同步状态
- **Receipt Parser** — 中英混合账单解析,命中模板自动套品牌 logo

## 工程结构

```
SubscribeApp/                       # Xcode project root
├── SubscribeApp/                   # 主 App target
│   ├── Models/                     # Subscription / WebhookEndpoint / PriceChange / SubscriptionTemplate / AppGroup
│   ├── Views/                      # Home / Trends / Schedule / Me + AddEdit / Webhooks / Receipt / Insights / YearInReview ...
│   ├── Intents/                    # App Intents + Shortcuts provider
│   ├── LiveActivity/               # TrialActivityAttributes + Manager
│   ├── Utilities/                  # WebhookDispatcher / Template / Sweeper, ReceiptParser, InsightsEngine, ExchangeRateService
│   ├── Preferences/                # AppSettings (NSUbiquitousKeyValueStore + UserDefaults 双写)
│   └── Theme/                      # Palette (light/dark)
├── SubscribeWidgets/               # Widget extension
├── SubscribeAppTests/              # 37 unit tests
├── AppStore/                       # 上架材料(描述、关键词、签名指引、TestFlight 清单…)
└── project.yml                     # xcodegen source of truth
```

## 构建 / 运行

依赖 **Xcode 16.2+**、**xcodegen**:

```bash
# 1. 安装 xcodegen(如未装)
brew install xcodegen

# 2. 生成 .xcodeproj
cd SubscribeApp
xcodegen generate

# 3. 打开
open SubscribeApp.xcodeproj

# 4. 在 Xcode 里首次运行前,需要填写 DEVELOPMENT_TEAM (见 AppStore/SIGNING.md)
```

模拟器直接 Build + Run 即可;真机(含 Widget / Live Activity / CloudKit 同步验证)需要付费 Apple Developer Program 账号签名。

### 单元测试

```bash
xcodebuild test \
  -project SubscribeApp.xcodeproj \
  -scheme SubscribeApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

目前 37 条测试覆盖 `ReceiptParser`、`InsightsEngine`、`WebhookTemplate`、`PriceChangeRecorder`。

## 上架到 TestFlight

1. 付费 Apple Developer Program($99/yr),拿 Team ID
2. 填进 `project.yml` 两处 `DEVELOPMENT_TEAM` 字段,重跑 `xcodegen generate`
3. Xcode 勾 Automatic signing、加 Capabilities(iCloud / App Groups / Push / Background Modes)
4. App Store Connect 建 App,名字填 `订算` / 英文 `Subtally`
5. Archive → Upload → 等 ASC 处理 15–30 分钟 → TestFlight 可见

详细步骤见 [AppStore/TESTFLIGHT.md](AppStore/TESTFLIGHT.md) 与 [AppStore/SIGNING.md](AppStore/SIGNING.md)。

## 隐私

- 全部数据存本地 SwiftData + 用户私人 iCloud(CloudKit Private Database)
- 不接分析 SDK、不传第三方服务器、不投放广告、不采集个人信息
- Webhook 由用户主动配置并自担 endpoint,HMAC 签名可验真
- 已按 Apple 要求附 [PrivacyInfo.xcprivacy](SubscribeApp/PrivacyInfo.xcprivacy)

## 路线图

- [ ] App Lock / Face ID
- [ ] 订阅暂停 / 归档(非删除)
- [ ] 首页搜索 + 状态筛选
- [ ] 价格预警通知(已有 `PriceChange` 模型,缺规则 + 推送)
- [ ] CSV / JSON 导出导入
- [ ] 月度预算警戒线
- [ ] Interactive Widget "已续费" 按钮 (iOS 17+ AppIntent widget)
- [ ] 英文 Localization
- [ ] Apple Watch / visionOS target

## 许可

尚未设置开源许可证,默认 All Rights Reserved。如需二次发行或商用请先联系作者。
