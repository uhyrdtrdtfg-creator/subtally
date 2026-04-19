import Foundation

/// 一键退订指引库 — 单条服务的退订攻略
struct CancellationGuide: Identifiable {
    let id: String          // 通常使用 slug 作为唯一键
    let serviceName: String
    let webURL: URL?
    let appDeeplink: URL?
    let steps: [String]
    let warnings: [String]
}

/// 内置指引库,从订阅详情页一键唤起
enum CancellationGuides {
    static let all: [CancellationGuide] = [
        // MARK: - 视频
        CancellationGuide(
            id: "netflix",
            serviceName: "Netflix",
            webURL: URL(string: "https://www.netflix.com/cancelplan"),
            appDeeplink: nil,
            steps: [
                "登录 Netflix 网页,进入「账户」页面",
                "在「会员资格与账单」中点击「取消会员资格」",
                "按提示完成确认即可在当期到期后停止扣费"
            ],
            warnings: [
                "通过 App Store 订阅的需在 iPhone「设置 > Apple ID > 订阅」中退订",
                "取消后到期前仍可继续观看,不会立即退款"
            ]
        ),
        CancellationGuide(
            id: "spotify",
            serviceName: "Spotify",
            webURL: URL(string: "https://www.spotify.com/account/subscription/"),
            appDeeplink: nil,
            steps: [
                "网页登录 Spotify 账户,进入订阅页",
                "点击当前套餐下方的「Change plan」",
                "向下滚动选择「Cancel Premium」并确认"
            ],
            warnings: [
                "iOS App 内订阅必须在 App Store 退订",
                "家庭/学生套餐取消后不会立即退款,会用满当期"
            ]
        ),
        CancellationGuide(
            id: "applemusic",
            serviceName: "Apple Music",
            webURL: URL(string: "https://apps.apple.com/account/subscriptions"),
            appDeeplink: URL(string: "itms-apps://apps.apple.com/account/subscriptions"),
            steps: [
                "打开「设置」点击顶部 Apple ID",
                "选择「订阅」,在列表里找到 Apple Music",
                "点击「取消订阅」并确认"
            ],
            warnings: [
                "Apple 订阅一律由 Apple 账号管理,无法在 music.apple.com 退订",
                "学生认证套餐取消后下次将按个人价计费"
            ]
        ),
        CancellationGuide(
            id: "appletv",
            serviceName: "Apple TV+",
            webURL: URL(string: "https://apps.apple.com/account/subscriptions"),
            appDeeplink: URL(string: "itms-apps://apps.apple.com/account/subscriptions"),
            steps: [
                "iPhone 打开「设置 > Apple ID > 订阅」",
                "找到 Apple TV+ 并点击进入",
                "选择「取消订阅」"
            ],
            warnings: [
                "购机赠送的免费 3 个月需手动取消,否则到期自动续费",
                "Apple One 套餐用户需取消整个 Apple One"
            ]
        ),
        CancellationGuide(
            id: "icloud",
            serviceName: "iCloud+",
            webURL: nil,
            appDeeplink: URL(string: "App-Prefs:APPLE_ACCOUNT&path=ICLOUD_SERVICE"),
            steps: [
                "iPhone 打开「设置 > Apple ID > iCloud」",
                "点击「管理账户存储 > 更改存储空间方案」",
                "选择「降级选项」,改为免费 5GB 或更小套餐"
            ],
            warnings: [
                "降级前请先备份/迁移文件,空间超额会停止备份与同步",
                "无法立即退款,新套餐将在下个计费周期生效"
            ]
        ),
        CancellationGuide(
            id: "youtube",
            serviceName: "YouTube Premium",
            webURL: URL(string: "https://www.youtube.com/paid_memberships"),
            appDeeplink: nil,
            steps: [
                "网页打开 youtube.com/paid_memberships",
                "在 Premium 下方点击「停用会员资格」",
                "选择「继续取消」并确认原因"
            ],
            warnings: [
                "iOS App 内开通的请到 App Store 订阅页退订,价格通常更贵",
                "取消后可继续使用至当期结束"
            ]
        ),
        CancellationGuide(
            id: "disney",
            serviceName: "Disney+",
            webURL: URL(string: "https://www.disneyplus.com/account/subscription"),
            appDeeplink: nil,
            steps: [
                "网页登录 Disney+,进入「账户 > 订阅」",
                "点击当前套餐右侧的「取消订阅」",
                "确认后会立即停止下一周期扣费"
            ],
            warnings: [
                "通过 Apple/Google 渠道订阅的需到对应商店退订",
                "捆绑包(Disney Bundle)需整体取消"
            ]
        ),
        CancellationGuide(
            id: "hbo",
            serviceName: "HBO Max / Max",
            webURL: URL(string: "https://auth.max.com/subscription"),
            appDeeplink: nil,
            steps: [
                "网页登录 Max 账户,进入「Subscription」",
                "点击「Manage Subscription > Cancel Subscription」",
                "按提示完成留存挽回流程"
            ],
            warnings: [
                "Apple/Google 计费的请到对应商店退订",
                "退订挽留页面常推送 50% 折扣,自行衡量是否接受"
            ]
        ),
        CancellationGuide(
            id: "amazonprime",
            serviceName: "Prime Video",
            webURL: URL(string: "https://www.amazon.com/gp/video/settings"),
            appDeeplink: nil,
            steps: [
                "登录 Amazon,进入「Prime Video Settings」",
                "在「Channels」或「Your Account」中找到对应订阅",
                "点击「End Subscription」并确认"
            ],
            warnings: [
                "如同时订阅了 Amazon Prime,取消 Prime 即可一次性结束 Prime Video",
                "Channels 频道单独取消,不影响主 Prime"
            ]
        ),
        CancellationGuide(
            id: "bilibili",
            serviceName: "B 站大会员",
            webURL: URL(string: "https://account.bilibili.com/account/big/myPackage"),
            appDeeplink: URL(string: "bilibili://"),
            steps: [
                "App 内打开「我的 > 大会员 > 自动续费管理」",
                "点击「关闭自动续费」",
                "如使用 Apple 续费请到 App Store 订阅页退订"
            ],
            warnings: [
                "关闭后已购买的会员仍可使用至到期日",
                "Apple 渠道每月价格较高,推荐 Web/支付宝渠道"
            ]
        ),
        CancellationGuide(
            id: "iqiyi",
            serviceName: "爱奇艺 VIP",
            webURL: URL(string: "https://vip.iqiyi.com/autorenew.html"),
            appDeeplink: URL(string: "iqiyi://"),
            steps: [
                "网页登录爱奇艺,打开「自动续费管理」",
                "选择对应套餐点击「关闭自动续费」",
                "微信/支付宝签约的会跳转对应 App 完成解约"
            ],
            warnings: [
                "Apple ID 续费请到 App Store 订阅退订",
                "黄金/星钻 VIP 是不同套餐,需分别取消"
            ]
        ),
        CancellationGuide(
            id: "tencentqq",
            serviceName: "腾讯视频 VIP",
            webURL: URL(string: "https://film.qq.com/x/account/auto_pay/"),
            appDeeplink: URL(string: "tenvideo://"),
            steps: [
                "App 内点击「我的 > 我的 VIP > 自动续费管理」",
                "选择套餐关闭自动续费",
                "微信支付签约可在「微信 > 我 > 服务 > 钱包 > 支付设置 > 自动续费」中解约"
            ],
            warnings: [
                "SVIP / VIP 套餐不互通,需要分别取消",
                "Apple 渠道开通的须在 iPhone 设置内退订"
            ]
        ),
        CancellationGuide(
            id: "youku",
            serviceName: "优酷 VIP",
            webURL: URL(string: "https://vip.youku.com/member/autorenewal"),
            appDeeplink: URL(string: "youku://"),
            steps: [
                "网页打开优酷自动续费管理页",
                "找到对应套餐,点击「取消续费」",
                "支付宝签约也可在「支付宝 > 我的 > 设置 > 支付设置 > 免密支付/自动扣款」中解约"
            ],
            warnings: [
                "酷喵会员(电视端)须单独取消",
                "Apple 渠道开通的请到 App Store 订阅页退订"
            ]
        ),
        CancellationGuide(
            id: "mangotv",
            serviceName: "芒果 TV",
            webURL: URL(string: "https://order.mgtv.com/vip/auto/list"),
            appDeeplink: URL(string: "imgtv://"),
            steps: [
                "App 内点击「我的 > 我的会员 > 自动续费管理」",
                "选择对应套餐点击「关闭自动续费」",
                "微信/支付宝签约也可在对应 App 解约"
            ],
            warnings: [
                "全屏 / 移动 / PC 端会员是不同套餐",
                "Apple 渠道价格较高,可考虑切换支付宝/微信续费"
            ]
        ),
        CancellationGuide(
            id: "neteasecloudmusic",
            serviceName: "网易云音乐黑胶 VIP",
            webURL: URL(string: "https://music.163.com/store/m/product/order/auto/sign?type=2"),
            appDeeplink: URL(string: "orpheus://"),
            steps: [
                "App 内进入「我的 > 黑胶 VIP > 续费管理」",
                "选择「关闭连续包月/包年」",
                "支付宝/微信签约的可在对应 App「自动扣费」中解约"
            ],
            warnings: [
                "Apple ID 续费请到 App Store 订阅页退订",
                "关闭后当期黑胶仍可正常使用"
            ]
        ),
        CancellationGuide(
            id: "qq",
            serviceName: "QQ 音乐绿钻",
            webURL: URL(string: "https://y.qq.com/portal/profile.html"),
            appDeeplink: URL(string: "qqmusic://"),
            steps: [
                "App 内点击「我的 > 我的会员 > 自动续费管理」",
                "选择「绿钻豪华版/SVIP」点击关闭",
                "微信支付签约可在「微信 > 服务 > 支付设置 > 自动续费」解约"
            ],
            warnings: [
                "豪华绿钻与 SVIP 是不同套餐,需要分别检查",
                "Apple 渠道续费请到 iPhone 设置退订"
            ]
        ),
        CancellationGuide(
            id: "baidu",
            serviceName: "百度网盘超级会员",
            webURL: URL(string: "https://pan.baidu.com/disk/main#/transfer/list"),
            appDeeplink: URL(string: "baiduboxapp://"),
            steps: [
                "App 内点击「我的 > 我的超级会员 > 自动续费管理」",
                "选择「关闭自动续费」",
                "微信/支付宝签约可在对应 App 内解约"
            ],
            warnings: [
                "关闭后空间内文件不会被删除,但超出免费额度无法继续上传",
                "Apple 渠道续费价格较高,推荐其他渠道"
            ]
        ),
        CancellationGuide(
            id: "alibabadotcom",
            serviceName: "阿里云盘",
            webURL: URL(string: "https://www.aliyundrive.com/drive/me"),
            appDeeplink: URL(string: "smartdrive://"),
            steps: [
                "App 内点击「我的 > 自动续费管理」",
                "选择套餐点击「取消自动续费」",
                "支付宝签约可在「支付宝 > 我的 > 设置 > 免密支付」中关闭"
            ],
            warnings: [
                "降级后超出空间的文件 30 天内仍可下载,但不再同步",
                "8TB / 6TB 等大容量套餐解约后将按超额限制只读"
            ]
        ),
        CancellationGuide(
            id: "jd",
            serviceName: "京东 PLUS",
            webURL: URL(string: "https://plus.m.jd.com/index"),
            appDeeplink: URL(string: "openapp.jdmobile://"),
            steps: [
                "京东 App 搜索「PLUS 会员」进入个人中心",
                "点击「续费管理 > 关闭自动续费」",
                "微信/支付宝签约还需到对应 App 取消免密扣款"
            ],
            warnings: [
                "联合会员(爱奇艺/腾讯视频)需到对方平台单独退订",
                "已发放的优惠券不会因关闭续费而立即失效"
            ]
        ),
        CancellationGuide(
            id: "taobao88vip",
            serviceName: "淘宝 88VIP",
            webURL: URL(string: "https://h5.m.taobao.com/88/index.htm"),
            appDeeplink: URL(string: "taobao://"),
            steps: [
                "淘宝 App 搜索「88VIP」进入会员中心",
                "点击「续费管理 > 关闭自动续费」",
                "支付宝签约请到「支付宝 > 设置 > 支付设置 > 免密支付/自动扣款」解约"
            ],
            warnings: [
                "88VIP 联合会员(优酷/饿了么/网易云)需自行评估是否还需要",
                "高价值用户(淘气值 ≥1000)续费仅 88 元/年"
            ]
        ),
        CancellationGuide(
            id: "meituan",
            serviceName: "美团会员",
            webURL: nil,
            appDeeplink: URL(string: "imeituan://"),
            steps: [
                "美团 App 点击「我的 > 美团会员」",
                "进入「自动续费管理」点击「关闭」",
                "如有微信支付签约,请到「微信 > 服务 > 支付设置 > 自动续费」解约"
            ],
            warnings: [
                "外卖神券包等附加权益会随会员到期失效",
                "Apple 渠道开通须到 App Store 订阅退订"
            ]
        ),
        CancellationGuide(
            id: "notion",
            serviceName: "Notion",
            webURL: URL(string: "https://www.notion.so/my-integrations"),
            appDeeplink: nil,
            steps: [
                "网页打开 Notion,进入「Settings & Members > Plans」",
                "点击「Change plan」选择 Free",
                "确认降级,当前周期结束后生效"
            ],
            warnings: [
                "降级后超出免费块数的内容仍可读但无法编辑",
                "工作区有多名成员的请先转让所有权或导出数据"
            ]
        ),
        CancellationGuide(
            id: "adobe",
            serviceName: "Adobe Creative Cloud",
            webURL: URL(string: "https://account.adobe.com/plans"),
            appDeeplink: nil,
            steps: [
                "登录 account.adobe.com,进入「Plans」",
                "选择对应方案点击「Manage plan > Cancel your plan」",
                "按提示完成退订(可能需要回答留存问题)"
            ],
            warnings: [
                "年付月扣方案提前取消会收取剩余金额 50% 违约金",
                "退订后云存储 90 天内仍可下载,之后将清除"
            ]
        ),
        CancellationGuide(
            id: "microsoft365",
            serviceName: "Microsoft 365",
            webURL: URL(string: "https://account.microsoft.com/services"),
            appDeeplink: nil,
            steps: [
                "登录 account.microsoft.com,进入「服务和订阅」",
                "找到 Microsoft 365 点击「管理 > 取消订阅」",
                "如开启了定期账单,需关闭「定期账单」选项"
            ],
            warnings: [
                "OneDrive 超出 5GB 的文件需在 30 天内备份,否则进入只读",
                "家庭版用户取消会影响所有共享成员"
            ]
        ),
        CancellationGuide(
            id: "figma",
            serviceName: "Figma Professional",
            webURL: URL(string: "https://www.figma.com/settings"),
            appDeeplink: nil,
            steps: [
                "网页登录 Figma,进入团队设置「Settings > Plan」",
                "点击「Change plan」选择 Starter (Free)",
                "确认降级,按比例退还差价"
            ],
            warnings: [
                "降级后每个团队最多 3 个文件可编辑,其余进入只读",
                "FigJam 是独立计费,需单独取消"
            ]
        ),
        CancellationGuide(
            id: "github",
            serviceName: "GitHub Copilot",
            webURL: URL(string: "https://github.com/settings/billing"),
            appDeeplink: nil,
            steps: [
                "登录 GitHub,进入「Settings > Billing and plans」",
                "在 Copilot 区块点击「Cancel trial / Cancel」",
                "确认后将在当前计费周期结束后停止"
            ],
            warnings: [
                "组织席位需要管理员从 Org Billing 中移除",
                "学生认证用户本身免费,无需退订"
            ]
        ),
        CancellationGuide(
            id: "openai",
            serviceName: "ChatGPT Plus",
            webURL: URL(string: "https://chatgpt.com/#settings/Subscription"),
            appDeeplink: nil,
            steps: [
                "网页登录 ChatGPT,点击左下头像 > Settings > Subscription",
                "点击「Manage my subscription」跳转 Stripe 账单页",
                "选择「Cancel plan」并确认"
            ],
            warnings: [
                "iOS App 内订阅必须在 App Store 退订(价格更贵)",
                "Team / Enterprise 套餐有最低承诺期,提前取消可能扣费"
            ]
        ),
        CancellationGuide(
            id: "anthropic",
            serviceName: "Claude Pro / Max",
            webURL: URL(string: "https://claude.ai/settings/billing"),
            appDeeplink: nil,
            steps: [
                "网页登录 claude.ai,点击左下头像 > Settings > Billing",
                "点击「Manage subscription」跳转账单页",
                "选择「Cancel plan」并确认"
            ],
            warnings: [
                "iOS / Android App 内订阅请到对应应用商店退订",
                "取消后到期日前仍享有 Pro 配额"
            ]
        ),
        CancellationGuide(
            id: "cursor",
            serviceName: "Cursor Pro",
            webURL: URL(string: "https://www.cursor.com/settings"),
            appDeeplink: nil,
            steps: [
                "登录 cursor.com,进入「Settings > Billing」",
                "点击「Manage Subscription」进入 Stripe 后台",
                "选择「Cancel plan」并确认"
            ],
            warnings: [
                "退订后免费版仅有限量 GPT-4 / Claude 调用",
                "年付套餐提前取消通常按已用月折算后退还"
            ]
        ),
        CancellationGuide(
            id: "midjourney",
            serviceName: "Midjourney",
            webURL: URL(string: "https://www.midjourney.com/account/"),
            appDeeplink: nil,
            steps: [
                "网页登录 midjourney.com,进入「Manage Sub」",
                "点击「Cancel Plan」",
                "选择立即取消或在当期结束后取消"
            ],
            warnings: [
                "立即取消会按比例退款,但隐身模式立刻失效",
                "GPU Hours 不结转,取消前请尽量用完"
            ]
        ),

        // MARK: - 其他常见
        CancellationGuide(
            id: "googleone",
            serviceName: "Google One",
            webURL: URL(string: "https://one.google.com/storage"),
            appDeeplink: nil,
            steps: [
                "网页登录 one.google.com,进入「Settings > Membership」",
                "点击「Cancel membership」",
                "选择降级到免费 15GB 套餐"
            ],
            warnings: [
                "iOS App 内购买须到 App Store 订阅退订",
                "超出 15GB 后无法继续上传 Gmail / Photos"
            ]
        ),
        CancellationGuide(
            id: "dropbox",
            serviceName: "Dropbox Plus",
            webURL: URL(string: "https://www.dropbox.com/account/plan"),
            appDeeplink: nil,
            steps: [
                "网页登录 Dropbox,进入「Plan」",
                "点击「Cancel plan」并选择降级原因",
                "完成确认后到期前继续保留 Plus 权益"
            ],
            warnings: [
                "降级后仅保留 2GB 免费空间,超额文件不会同步",
                "年付套餐取消后剩余金额按 30 天内可申请退款"
            ]
        ),
        CancellationGuide(
            id: "perplexity",
            serviceName: "Perplexity Pro",
            webURL: URL(string: "https://www.perplexity.ai/settings/account"),
            appDeeplink: nil,
            steps: [
                "网页登录 Perplexity,进入「Settings > Account」",
                "点击「Manage Subscription」跳转 Stripe",
                "选择「Cancel plan」并确认"
            ],
            warnings: [
                "iOS App 内订阅请到 App Store 退订",
                "通过运营商赠送的(如 Revolut)需到对方 App 取消"
            ]
        )
    ]

    /// 先按 slug 精确匹配,再按服务名做模糊匹配
    static func find(slug: String, name: String) -> CancellationGuide? {
        let trimmedSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedSlug.isEmpty,
           let hit = all.first(where: { $0.id.lowercased() == trimmedSlug }) {
            return hit
        }

        let normalizedName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")

        guard !normalizedName.isEmpty else { return nil }

        // 直接子串匹配
        if let hit = all.first(where: { guide in
            let candidate = guide.serviceName
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "+", with: "")
            return candidate.contains(normalizedName) || normalizedName.contains(candidate)
        }) {
            return hit
        }

        // 中文关键词命中(按服务名首段)
        let chineseHints: [(String, String)] = [
            ("netflix", "netflix"),
            ("奈飞", "netflix"),
            ("爱奇艺", "iqiyi"),
            ("腾讯视频", "tencentqq"),
            ("优酷", "youku"),
            ("芒果", "mangotv"),
            ("b站", "bilibili"),
            ("哔哩", "bilibili"),
            ("网易云", "neteasecloudmusic"),
            ("qq音乐", "qq"),
            ("百度网盘", "baidu"),
            ("阿里云盘", "alibabadotcom"),
            ("京东", "jd"),
            ("淘宝", "taobao88vip"),
            ("88vip", "taobao88vip"),
            ("美团", "meituan"),
            ("icloud", "icloud"),
            ("appletv", "appletv"),
            ("applemusic", "applemusic"),
            ("youtube", "youtube"),
            ("disney", "disney"),
            ("hbo", "hbo"),
            ("max", "hbo"),
            ("prime", "amazonprime"),
            ("notion", "notion"),
            ("adobe", "adobe"),
            ("microsoft", "microsoft365"),
            ("office", "microsoft365"),
            ("figma", "figma"),
            ("copilot", "github"),
            ("github", "github"),
            ("chatgpt", "openai"),
            ("openai", "openai"),
            ("claude", "anthropic"),
            ("anthropic", "anthropic"),
            ("cursor", "cursor"),
            ("midjourney", "midjourney"),
            ("perplexity", "perplexity"),
            ("googleone", "googleone"),
            ("google one", "googleone"),
            ("dropbox", "dropbox"),
            ("spotify", "spotify")
        ]
        for (keyword, slugKey) in chineseHints {
            if normalizedName.contains(keyword.lowercased()),
               let hit = all.first(where: { $0.id == slugKey }) {
                return hit
            }
        }

        return nil
    }
}
