# App Store 截图待办

App Store Connect 至少要求 **6.7" iPhone**(iPhone 15 Pro Max / 16 Pro Max,1290 × 2796 px)的截图,5–10 张。下面列出本次首发需要的 5 张及拍摄要点。

## 必交 5 张(顺序即审核展示顺序)

| # | 场景 | 路径 / 操作 | 文案叠加建议 |
|---|------|-------------|--------------|
| 1 | **Home(总览)** | App 首页,展示「本月总支出」+ 即将续费列表(至少 4 项,涵盖流媒体、AI、云盘) | 「一眼看清每月订阅花费」 |
| 2 | **Trends(趋势)** | 趋势/分析 Tab,展示近 12 个月折线图与分类堆叠柱状图 | 「读懂你的订阅曲线」 |
| 3 | **Schedule(日历)** | 日历/时间线视图,显示当月续费节点与试用到期标记 | 「提前知道,不再被扣」 |
| 4 | **Webhook 编辑页** | 设置 → 自动化 → 新建/编辑 Webhook,字段全填(URL、事件类型、Body 模板预览) | 「打通你的工作流」 |
| 5 | **试用 Banner / Live Activity** | 详情页中正在倒计时的试用 + 锁屏 Live Activity 拼图 | 「免费试用,到点提醒」 |

## 拍摄步骤(Simulator)

1. 打开 Xcode → 选择 `iPhone 16 Pro Max`(或 `iPhone 15 Pro Max`)模拟器,确保为 6.7" 等效尺寸,系统语言可分别切到「简体中文」与「English」分别拍。
2. `xcrun simctl boot "iPhone 16 Pro Max"` 后 `Run` 当前 scheme。
3. 用 Demo 数据(种子脚本或手动添加 8–12 条覆盖各类型订阅,含 1 条试用中、1 条本周续费)。
4. 切到目标页面,菜单栏 `Device → Trigger Screenshot`,或快捷键 `⌘ + S`,文件保存到桌面。
5. 文件命名规范:`6.7_zh_01_home.png`、`6.7_en_03_schedule.png` …
6. 试用 Banner / Live Activity 一张:在 Simulator 用 `Features → Toggle In-Call Status Bar` 唤出锁屏样式,或用真机投屏录屏后截图。
7. (可选)用 [Fastlane frameit](https://docs.fastlane.tools/actions/frameit/) 或 Figma 加状态栏与文案叠加,提升点击率。

## 锁屏 / Dynamic Island 拍摄注意

Live Activity 在 Simulator 锁屏可能不渲染完整动效,建议用真机 + QuickTime 录屏,再 1290×2796 截帧。

## 其他可选尺寸

- 6.5"(可由 6.7" 自动派生,App Store Connect 会接受同尺寸覆盖)
- iPad Pro 12.9"(2048 × 2732):若上架 iPad 需另拍 5 张

## 文案与本地化

- 中文截图叠加用思源黑体 Heavy / 苹方 Heavy
- 英文用 SF Pro Display Black
- 主色仍用品牌琥珀 `#D4A848`,深底 `#0C0C10`,字色 `#F6F5F2`

## 提交前检查清单

- [ ] 5 张 6.7" 中文截图
- [ ] 5 张 6.7" 英文截图
- [ ] 状态栏满电(Simulator 默认就是满信号满电)
- [ ] 不出现真实姓名/邮箱/价格变形数字
- [ ] 不出现竞品 Logo(Netflix、Spotify 图标可以但避免明显商标)
