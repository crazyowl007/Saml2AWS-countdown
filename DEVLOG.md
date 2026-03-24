# 开发进度

## v1.0 — 初始版本 (2026-03-24)

### 已完成功能

#### 核心功能
- [x] macOS 菜单栏显示 SAML session 倒计时
- [x] 读取 `~/.aws/credentials` 的 `[saml]` section 中的 `x_security_token_expires`
- [x] 1 秒刷新间隔，实时更新倒计时
- [x] 文件监控（DispatchSource + 60s 轮询），凭证文件变化自动刷新

#### 状态显示
- [x] Active（>30m）: 绿色盾牌图标
- [x] Expiring Soon（5-30m）: 黄色警告图标
- [x] Critical（≤5m）: 红色警告图标
- [x] Expired: 红色失效图标
- [x] Unknown: 灰色问号图标

#### 通知
- [x] 到期前 30m、15m、5m、1m 推送通知
- [x] 到期时推送通知
- [x] 前台也显示通知（banner + sound）

#### 系统集成
- [x] 开机自启动（SMAppService）
- [x] 无 Dock 图标（LSUIElement）
- [x] Quit 按钮

#### Refresh 功能（saml2aws login 自动化）
- [x] Refresh Session 按钮
- [x] 通过 `forkpty` 创建伪终端运行 `saml2aws login --skip-prompt --force`
- [x] 密码从 macOS Keychain 自动读取
- [x] MFA 自动选择（默认第一个选项 PUSH MFA，发送 Enter 确认）
- [x] 等待 Okta Push 审批，手机批准后自动完成
- [x] 状态实时显示：Starting → MFA selected → Waiting for push → Success/Failed
- [x] Cancel 按钮可取消进行中的登录
- [x] 120 秒超时保护
- [x] 防重复点击

### 已知限制
- saml2aws 的密码需要先在终端手动运行一次 `saml2aws login` 存入 Keychain
- MFA 默认选择第一个选项（PUSH），如果 PUSH 不是第一个选项需要修改代码
- 仅支持 Homebrew 安装的 saml2aws（路径硬编码为 `/opt/homebrew/bin/saml2aws`）
- 仅监控 `[saml]` profile，不支持其他 profile 名

### 可能的后续改进
- [ ] 支持配置 saml2aws 路径
- [ ] 支持选择不同的 MFA 方式
- [ ] 支持多个 AWS profile
- [ ] 支持配置 saml2aws 的 IDP account（当前仅 default）
- [ ] 到期前自动 refresh
- [ ] App 图标
