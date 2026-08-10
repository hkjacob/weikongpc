# 微控儿童电脑 PC 客户端 (WeikongPC Client)

> 让家长简单了解和管理孩子使用电脑的情况：电脑是否开机、用了多久、必要时能否远程关机。

## 关注公众号

<p align="center">
  <img src="csapp_weikongpc_client/docs/assets/wechat-qr.jpg" alt="微控儿童电脑PC 微信公众号" width="200"/>
</p>

扫码关注微信公众号「**微控儿童电脑PC**」，在公众号菜单中选择「绑定」菜单，扫描安装程序生成的设备二维码即可关联设备，开始远程管理孩子的电脑。

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
┌─────────────────┐        ┌─────────────────┐
│  WeikongPC.exe  │  beat  │  网关 weikongpc.com
│  Session 0 服务  │ ────► │  云函数 A (PC 端)
│  每 180s 上报    │ ◄───  │  云函数 B (微信端)
│  执行关机命令    │  201  │  MySQL 数据库
└─────────────────┘        └─────────────────┘
                                  ▲
                                  │
                           ┌──────────────┐
                           │  微信公众号   │
                           │  元宝智能体   │
                           └──────────────┘
```

### 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| PC 客户端 | C# .NET 8 + Native AOT | 单文件 exe，6 MB，无运行时依赖 |
| 安装程序 | Inno Setup 6 + PowerShell | 三种模式：安装/修复/卸载 |
| 设备身份 | SHA-256 哈希 | CPU+主板序列号 → 32 位 uid |
| 鉴权 | HTTP Header | X-Uid / X-Uid-Key |
| 协议 | 状态码驱动 | 200 正常 / 201 关机 / 401 失败 / 429 过频 |

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

### 安装

双击 `WeikongPC-Setup-1.0.0.exe`，按向导完成安装。安装程序会：

1. 复制文件到 `C:\Program Files\WeikongPC\`
2. 生成 `WeikongPC.ini`（含设备 uid 和 key）
3. 生成设备绑定二维码
4. 注册 Windows 服务（开机自启）
5. 显示公众号二维码和绑定二维码

### 卸载

通过控制面板 → 程序和功能 → 卸载。

### 命令行

```cmd
WeikongPC.exe install      :: 注册为 Windows 服务（需管理员）
WeikongPC.exe uninstall    :: 注销 Windows 服务（需管理员）
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
