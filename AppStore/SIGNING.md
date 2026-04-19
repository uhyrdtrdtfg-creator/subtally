# 签名与上架指引(SIGNING.md)

本文档说明把「订算 (Subtally)」打包提交到 App Store / TestFlight 之前需要完成的签名与 Capabilities 配置。**全程不需要修改任何 Swift 源码。**

> 注:内部代号仍为 `SubscribeApp`(Xcode target、Bundle ID、App Group、iCloud Container 均保留),用户可见的品牌名是「订算 / Subtally」,两者故意解耦,换品牌时不必重配 CloudKit。

> Bundle ID: `com.samxiao.SubscribeApp`
> Widget Bundle ID: `com.samxiao.SubscribeApp.SubscribeWidgets`(以 `project.yml` 实际值为准)
> App Group: `group.com.samxiao.SubscribeApp`
> iCloud Container: `iCloud.com.samxiao.SubscribeApp`

---

## 1. 拿到 Team ID

1. 打开 <https://developer.apple.com/account>,顶部右侧切换到对应 Apple Developer Program 账号。
2. 左栏 **Membership details**(或旧版 Membership)页面里的 **Team ID** 字段,即一串 **10 位字母+数字**(例如 `A1B2C3D4E5`)。
3. 复制下来,后面要填到两个地方。

> 如果没有付费开发者账号,需要先加入 Apple Developer Program ($99/年)才能上架。

## 2. 写入 `project.yml` 并重新生成 Xcode 工程

打开 `/Users/samxiao/subsribe_app_done/SubscribeApp/project.yml`,把:

```yaml
DEVELOPMENT_TEAM: ""
```

改成:

```yaml
DEVELOPMENT_TEAM: "你的10位TeamID"
```

> ⚠️ 文件里通常有 **两处** `DEVELOPMENT_TEAM`(SubscribeApp 主 target 和 SubscribeWidgets target),**两处都要改**。

然后在仓库根目录重跑:

```bash
cd /Users/samxiao/subsribe_app_done/SubscribeApp
xcodegen generate
```

成功后会刷新 `SubscribeApp.xcodeproj`,Xcode 重新打开即可。

## 3. Xcode 内启用自动签名

1. Xcode 打开 `SubscribeApp.xcodeproj`。
2. 左栏选中 **SubscribeApp** target → 顶部 **Signing & Capabilities**。
3. 勾选 **Automatically manage signing**。
4. **Team** 下拉里选你刚才那个 Team。
5. **Bundle Identifier** 应显示 `com.samxiao.SubscribeApp`。
6. 重复以上步骤设置 **SubscribeWidgets** target,Team 必须相同。

## 4. 必须勾上的 Capabilities

在 SubscribeApp 主 target 的 Signing & Capabilities 中,通过 **+ Capability** 添加并配置:

| Capability | 配置 |
|------------|------|
| **iCloud** | 勾 **CloudKit**、勾 **iCloud Documents**;在 Containers 中添加 `iCloud.com.samxiao.SubscribeApp` |
| **App Groups** | 添加 `group.com.samxiao.SubscribeApp` |
| **Push Notifications** | 直接添加即可 |
| **Background Modes** | 勾 **Remote notifications**、**Background fetch**(若需要后台续费检查) |
| **Live Activities** | 已通过 Info.plist 中的 `NSSupportsLiveActivities = YES` 启用,无需在 Capabilities 面板再加 |

**SubscribeWidgets** target 同样需要勾:
- **App Groups** → `group.com.samxiao.SubscribeApp`(必须,否则读不到主 App 写入的数据)
- **Push Notifications**(若 Live Activity 走 ActivityKit + APNs 远程更新)

## 5. Apple Developer Portal 创建容器与组

进入 <https://developer.apple.com/account/resources/identifiers/list>:

1. **Identifiers → App IDs**:确认 `com.samxiao.SubscribeApp` 与 widget 的 App ID 都已注册,且勾上了 iCloud(选 Include CloudKit support)、Push Notifications、App Groups。
2. **Identifiers → iCloud Containers**:**+** 新建 `iCloud.com.samxiao.SubscribeApp`(Description 随意)。
3. **Identifiers → App Groups**:**+** 新建 `group.com.samxiao.SubscribeApp`。
4. 回到主 App ID,把刚刚创建的 iCloud Container 与 App Group **关联**进去并 Save。
5. 回到 Xcode,Signing 面板点 **Try Again** 让 Provisioning Profile 重新拉取。

## 6. CloudKit Schema(首发)

打开 <https://icloud.developer.apple.com/dashboard/>:
- 选择 Container `iCloud.com.samxiao.SubscribeApp`
- **Development** 环境跑过一次 App 后,会自动创建 Record Types
- 验证无误后 **Deploy Schema to Production**

## 7. App Store Connect 准备

1. <https://appstoreconnect.apple.com> → **My Apps → +**
2. 平台 iOS、名称「订算」(英文 name 填 `Subtally`)、Primary Language Simplified Chinese、Bundle ID 选 `com.samxiao.SubscribeApp`、SKU 自定。
3. 把 `AppStore/` 目录下文件复制到对应字段:
   - `description-zh.txt` → 中文 App Description
   - `description-en.txt` → 英文 App Description
   - `keywords-zh.txt` / `keywords-en.txt` → Keywords
   - `release-notes-1.0.txt` → What's New(中英分别填)
   - `support-url.txt` → Support URL
   - `privacy-policy-url.txt` → Privacy Policy URL
4. 上传 5 张 6.7" 截图(详见 `screenshots-todo.md`)。
5. App Privacy 问卷:依据 `PrivacyInfo.xcprivacy` 如实填(不收集任何个人数据)。

## 8. Archive 与上传

1. Xcode 顶部 scheme 选 **SubscribeApp** + **Any iOS Device (arm64)**。
2. 菜单 **Product → Archive**(若提示找不到 device,先选真机或 Generic iOS Device)。
3. Archive 完成弹出 Organizer,选最新 Archive → **Distribute App → App Store Connect → Upload**。
4. 走完上传后等待 ASC 处理(15–30 分钟),TestFlight 即可看到。

## 9. 常见坑

- **Provisioning failed**:Capabilities 与 Portal 上的 App ID 不一致 → 在 Portal 上确认勾选,然后 Xcode 点 Try Again。
- **iCloud 同步无效**:容器名拼错(注意前缀 `iCloud.`),或 schema 没 Deploy 到 Production。
- **Widget 数据为空**:App Group 没在 widget target 勾上,或 widget 的 entitlement 缺失。
- **Live Activity 不出现**:Info.plist 缺 `NSSupportsLiveActivities = YES`(已加),且必须真机 iOS 16.1+ 测试。
- **审核被拒「Privacy Manifest」**:确认 `PrivacyInfo.xcprivacy` 已加入两个 target 的 Resources(`project.yml` 已配置,xcodegen 生成时会自动包含)。

---

完成上面 1–8 步后,即可在 TestFlight 内邀请测试员;一切就绪后从 ASC 提交审核。
