# 微控儿童电脑 PC 客户端 (WeikongPC Client)

> 让家长简单了解和管理孩子使用电脑的情况：电脑是否开机、用了多久、必要时能否远程关机。

## 关注公众号

<p align="center">
  <img src="csapp_weikongpc_client/docs/assets/wechat-qr.jpg" alt="微控儿童电脑PC 微信公众号" width="200"/>
</p>

安装客户端后，安装程序会自动打开设备绑定链接 `https://weikongpc.com/bind`，页面展示设备专属二维码。用微信扫码并关注公众号「**微控儿童电脑PC**」，即自动完成设备绑定，可在公众号中远程管理孩子的电脑。

> ⚠️ **如果使用官方服务器** `https://weikongpc.com/beat`，**必须先绑定微信公众号**。
> 若自建服务器，可忽略此步骤（详见 [服务器实现指南](csapp_weikongpc_client/docs/SERVER_IMPLEMENTATION.md)）。

## 官网

🌐 **https://weikongpc.com/**

## 项目背景

微控儿童电脑（WeikongPC）是一款运行在 Windows 电脑上的轻量级后台服务程序，用于帮助家长远程了解孩子电脑的使用情况，并在必要时远程关机。

本仓库仅包含 **PC 客户端** 和 **安装程序** 的源代码。云端后端（云函数、数据库、官网）**未开源**，但接口协议完全公开，可自建服务器对接。

### 核心功能

- 🖥️ **状态采集**：每 180 秒采集 CPU 使用率、内存使用率、进程列表
- 📡 **心跳上报**：通过 HTTP 上报到云端，家长可实时查看设备状态
- 🔌 **远程关机**：接收云端关机指令，执行正常关机（非硬断电）
- 🔒 **Session 0 服务**：作为 Windows 后台服务运行，开机自启，无界面
- 🔧 **自动安装**：安装程序自动生成设备身份、注册服务、展示绑定二维码

### 系统架构

```
PC 客户端 (本仓库)          云端 (不在本仓库)
┌─────────────────┐        ┌──────────────────────────────┐
│  WeikongPC.exe  │  beat  │  网关 weikongpc.com           │
│  Session 0 服务  │ ────► │  云函数 A (PC 端 /beat)       │
│  每 180s 上报    │ ◄───  │  云函数 B (微信端 /bind        │
│  执行关机命令    │  201  │            /bindcallback)     │
│  安装后打开      │        │  MySQL 数据库 (4 张表)        │
│  /bind 绑定链接  │ ────► │                              │
└────────┬────────┘        └──────────────┬───────────────┘
         │ 浏览器打开绑定页                  │ 回调 bindcallback
         ▼                                 ▼
┌─────────────────┐               ┌────────────────┐
│  设备绑定二维码  │               │  微信公众号    │
│  (带参数临时码)  │               │  元宝智能体    │
└─────────────────┘               └────────────────┘
```

### 微信绑定流程

1. **安装客户端**：安装程序生成设备身份（uid/uid_key）到 `WeikongPC.ini`，并打开绑定链接 `https://weikongpc.com/bind?uid=xxx&uid_key=xxx&ts=xxx`
2. **展示二维码**：后端校验设备身份后调用微信公众号接口，生成带参数临时二维码（场景值为 uid，有效期 30 天），页面展示二维码
3. **扫码关注即绑定**：家长用微信扫码并关注公众号，微信推送 `subscribe`/`SCAN` 事件到 `https://weikongpc.com/bindcallback`，后端将 openid 与设备 uid 写入绑定表并更新设备表
4. **远程管理**：绑定后即可通过公众号/元宝智能体查看设备状态、下发关机指令

### 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| PC 客户端 | C# .NET 8 + Native AOT | 单文件 exe，6 MB，无运行时依赖 |
| 安装程序 | Inno Setup 6 + PowerShell | 三种模式：安装/修复/卸载 |
| 设备身份 | SHA-256 哈希 | CPU+主板序列号 → 32 位 uid |
| 鉴权 | HTTP Header | X-Uid / X-Uid-Key |
| 协议 | 状态码驱动 | 200 正常 / 201 关机 / 401 失败 / 429 过频 |

## 云端接口

统一网关：`https://weikongpc.com`，共 3 个接口、2 个云函数（Node.js 18 HTTP Function，均绑定 VPC 访问 TDSQL-C MySQL）。

| 接口 | 方法 | 云函数 | 说明 |
|------|------|--------|------|
| `/beat` | POST | `nodeweb_weikongpc_beat` | PC 客户端心跳上报（详见 [beat 协议规范](csapp_weikongpc_client/docs/BEAT_PROTOCOL.md)） |
| `/bind` | GET | `nodeweb_weikongpc_mgmt` | 设备绑定页：校验设备身份，调用集成中心「公众号开放服务」生成带参数临时二维码 |
| `/bindcallback` | GET/POST | `nodeweb_weikongpc_mgmt` | 微信公众号回调：URL 验证 + 扫码关注/扫码事件绑定 |
| `/offiaccount/*` | POST | `nodeweb-weikongpc-7rs7ysvn-demo-scfweb` | 集成中心「公众号开放服务」：qrcode/create、oauth、token、模板消息、客服消息等 |

### 1. 设备绑定页 `/bind`

```
GET https://weikongpc.com/bind?uid=<32位设备标识>&uid_key=<16位密钥>&ts=<毫秒时间戳>
```

由安装程序在安装完成后用浏览器打开。流程：

1. 校验 `uid`（32 位哈希）、`uid_key`（16 位随机）、`ts`（10-13 位数字）
2. 查询设备表：设备不存在则以 uid/uid_key 登记（**设备注册路径**）；已存在则校验密钥
3. 调用集成中心「公众号开放服务」`POST /offiaccount/qrcode/create`（`QR_STR_SCENE`，scene_str = uid，有效期 30 天），返回二维码图片 URL
4. 返回 HTML 页面，内嵌二维码与操作指引

### 2. 公众号回调 `/bindcallback`

在公众号后台「设置与开发 → 基本配置 → 服务器配置」中配置：

| 配置项 | 值 |
|--------|-----|
| URL | `https://weikongpc.com/bindcallback` |
| Token | `wkpc_bind_token_2026`（与云函数环境变量 `WECHAT_TOKEN` 一致） |
| 消息加解密方式 | 明文模式 |

**GET（URL 验证）**：校验 `signature = sha1(sort(Token, timestamp, nonce))`，通过则原样返回 `echostr`。

**POST（事件推送）**：同样校验签名后解析 XML：

| 事件 | EventKey | 处理 |
|------|----------|------|
| `subscribe`（扫码关注） | `qrscene_<uid>` | 绑定：openid + uid 写入微信用户表、绑定表，更新设备表 `bound_openid`，回复「绑定成功」 |
| `SCAN`（已关注用户扫码） | `<uid>` | 同上 |
| `unsubscribe`（取关） | - | 微信用户表标记 `subscribe=0` |

回调必须 5 秒内响应，业务失败也回复文本消息而非 `success`（避免微信静默重试）。

### 微信公众号凭据

- 云函数 `nodeweb_weikongpc_mgmt` 环境变量：`WECHAT_TOKEN`（回调验签 Token，与公众号后台服务器配置一致）
- 集成中心「公众号开放服务」统一托管 `appId` / `appSecret`（注入到 `nodeweb-weikongpc-7rs7ysvn-demo-scfweb`），出二维码/模板消息等主动调用微信的接口统一走它

> ⚠️ 公众号后台需在「设置与开发 → 基本配置 → IP 白名单」中加入云函数出网 IP，否则主动调用微信 API 报 `errcode=40164`。当前只有集成函数会主动调微信，其**固定 EIP** 为 `101.34.34.227`。`/bindcallback` 只接收微信回调，不受白名单影响。

## 数据库设计

MySQL（TDSQL-C，库 `weikongpc-d6g8itpyf026b3c4f`），共 4 张表。

### t_device — 设备表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint unsigned PK | 自增主键 |
| uid | char(32) UNIQUE | 设备标识，CPU+主板序列号 SHA-256 哈希 |
| uid_key | char(16) | 接口鉴权密钥，安装时随机生成 |
| name | varchar(64) | 设备名称 |
| os | varchar(32) | 操作系统版本 |
| status | tinyint | 0 离线 / 1 在线 |
| shutdown_status | tinyint | 关机指令：0 无 / 1 待下发 / 2 已下发 |
| last_beat_at | datetime | 最后心跳时间 |
| last_ip | varchar(45) | 最后上报 IP |
| bound_openid | varchar(64) | 最后绑定的微信用户 openid |
| created_at / updated_at | datetime | 创建/更新时间 |

### t_device_log — 设备日志表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint unsigned PK | 自增主键 |
| uid | char(32) | 关联 t_device.uid |
| cpu_usage | decimal(5,2) | CPU 使用率 |
| mem_usage | decimal(5,2) | 内存使用率 |
| processes | json | 进程列表 |
| beat_time | datetime | 心跳上报时间 |
| cmd_time | datetime | 指令下发时间（NULL 无指令） |
| cmd_status | tinyint | 0 无指令 / 1 已下发关机 |
| created_at | datetime | 创建时间 |

### t_wechat_user — 微信用户表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint unsigned PK | 自增主键 |
| openid | varchar(64) UNIQUE | 微信用户 openid |
| nickname | varchar(64) | 微信昵称 |
| subscribe | tinyint | 1 已关注 / 0 已取关 |
| subscribe_time | datetime | 最近关注时间 |
| created_at / updated_at | datetime | 创建/更新时间 |

### t_wechat_device — 微信用户和设备绑定表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint unsigned PK | 自增主键 |
| openid | varchar(64) | 微信用户 openid |
| uid | char(32) | 关联 t_device.uid |
| status | tinyint | 1 已绑定 / 0 已解绑 |
| bind_time | datetime | 绑定时间 |
| unbind_time | datetime | 解绑时间（NULL 未解绑） |
| created_at / updated_at | datetime | 创建/更新时间 |

唯一键 `uk_openid_uid(openid, uid)`：一个微信用户可绑定多台设备，一台设备可被多个家庭成员绑定。

## 仓库结构

```
weikongpc/                                # GitHub 仓库根
├── README.md                            # 本文件
├── LICENSE                              # MIT 开源协议
├── .gitignore
└── csapp_weikongpc_client/              # PC 客户端项目
    ├── cswsv_weikongpc_report/          # PC 客户端源码
    │   ├── Program.cs                   # 单文件实现（约 400 行）
    │   └── cswsv_weikongpc_report.csproj # 项目配置（AOT 编译）
    └── installer/                       # 安装程序
        ├── installer.iss                # Inno Setup 脚本
        ├── scripts/
        │   ├── setup-helper.ps1         # 硬件识别 + ini 生成 + 二维码
        │   └── success-window.ps1       # WPF 成功页面
        └── assets/
            ├── LICENSE.txt              # 用户协议
            └── wechat-qr.jpg            # 公众号二维码
```

## 编译

### 环境要求

- .NET 8 SDK (8.0.423+)
- Visual Studio Build Tools 2022（含 C++ 桌面开发工作负载）
- Windows SDK 10.0.26100+
- Inno Setup 6.7+（编译安装程序）

### 编译客户端

```powershell
cd csapp_weikongpc_client\cswsv_weikongpc_report
dotnet publish -r win-x64 -c Release
# 产物：bin\Release\net8.0-windows\win-x64\publish\WeikongPC.exe (约 6 MB)
```

### 编译安装程序

```powershell
cd csapp_weikongpc_client\installer
ISCC.exe installer.iss
# 产物：output\WeikongPC-Setup-1.0.0.exe (约 4 MB)
```

## 运行

### 安装方式一：ZIP + PowerShell 脚本（推荐，无需签名）

1. 下载 `WeikongPC-Client-v1.0.0.zip` 并解压
2. 右键 `install.ps1` → 使用 PowerShell 运行（管理员）
3. 脚本自动完成：复制文件 → 生成设备标识 → 注册服务 → 启动服务
4. 自动打开浏览器绑定页面，扫码完成微信绑定

> ✅ 优点：PS1 脚本 + `sc.exe` 都是系统组件，**不会触发 SmartScreen 和智能应用控制**，无需数字签名。
> 💡 首次安装后客户端会收到 401（未绑定），会自动每 60 秒重试，直到在微信中完成绑定。

### 安装方式二：Inno Setup 安装包

双击 `WeikongPC-Setup-1.0.0.exe`，按向导完成安装。安装程序会：

1. 复制文件到 `C:\Program Files\WeikongPC\`
2. 生成 `WeikongPC.ini`（含设备 uid 和 key）
3. 生成设备绑定二维码
4. 注册 Windows 服务（开机自启）
5. 显示公众号二维码和绑定二维码

> ⚠️ 注意：无数字签名的 exe 可能被 SmartScreen 或智能应用控制拦截。

### 卸载

方式一：右键 `uninstall.ps1` → 使用 PowerShell 运行（管理员）
方式二：控制面板 → 程序和功能 → 卸载。

### 命令行

```cmd
WeikongPC.exe install      :: 注册为 Windows 服务（需管理员）
WeikongPC.exe uninstall    :: 注销 Windows 服务（需管理员）
WeikongPC.exe rebind       :: 打开浏览器设备绑定页面
WeikongPC.exe              :: 直接运行（调试用，Ctrl+C 退出）
```

## 兼容性

- ✅ Windows 10 1607 (2016 年 7 月) 及以上
- ✅ Windows 11 全版本
- ✅ Windows Server 2016/2019/2022/2025
- ❌ Windows 7（.NET 8 AOT 不支持）

## 开源协议

MIT License - 详见 [LICENSE](LICENSE)

## 相关链接

- 🌐 官网：https://weikongpc.com/
- 📧 微信公众号：微控儿童电脑PC
- 🤖 元宝智能体：通过公众号接入

## 协议文档

- 📡 **[beat 协议规范](csapp_weikongpc_client/docs/BEAT_PROTOCOL.md)**：客户端与服务器端的通信协议（HTTP Header 鉴权 + 状态码驱动）
- 🛠️ **[服务器实现指南](csapp_weikongpc_client/docs/SERVER_IMPLEMENTATION.md)**：如何自建服务器对接本客户端（Node.js / Python / Go / Java 等）

## 贡献

欢迎提交 Issue 和 Pull Request。

---

© 2026 weikongpc.com
