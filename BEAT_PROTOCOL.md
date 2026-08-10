# WeikongPC Beat 协议（v1.0）

PC 客户端 → 服务器端的心跳上报接口规范。

> ⚠️ **关于服务器实现**
> - 服务器端**完全可以自行实现**（自建 HTTP 服务即可）
> - 若使用**官方服务器** `https://weikongpc.com/beat`，必须先关注微信公众号「微控儿童电脑PC」并在公众号菜单「绑定」中扫码关联设备
> - 官方服务器的开源版本暂未发布，本协议可供第三方实现对接

---

## 1. 接口地址

```
POST {ServerUrl}/beat
```

默认服务器地址：`https://weikongpc.com/beat`（可在 `WeikongPC.ini` 的 `[server] url` 中修改）

## 2. 鉴权方式

使用 HTTP Header 传递设备身份凭证（**不要放在 body 里**）：

| Header | 格式 | 说明 |
|--------|------|------|
| `X-Uid` | 32 位 hex（SHA-256） | 设备唯一标识 |
| `X-Uid-Key` | 16 位字符（字母+数字） | 设备密钥 |

**生成规则**：

```text
raw = "{CPU 序列号}|{主板序列号}"
uid = SHA256(raw).hex.substring(0, 32)
uid_key = 16 位随机字符（去掉易混字符：0/O/1/l/I）
```

CPU 序列号获取（PowerShell）：
```powershell
Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty ProcessorId
```

主板序列号获取（PowerShell）：
```powershell
Get-CimInstance Win32_BaseBoard | Select-Object -First 1 -ExpandProperty SerialNumber
```

⚠️ **关键约束**：
- 同一台电脑必须**始终生成相同的 uid**（CPU+主板序列号稳定不变）
- `uid_key` 由服务器端生成，**首次绑定后写入 ini 文件**，客户端需持久保存

## 3. 请求体（JSON）

```json
{
  "name": "小明学习电脑",
  "os": "Windows 11 Pro 24H2",
  "cpu_usage": 35.50,
  "mem_usage": 62.30,
  "boot_time": "2026-08-10 08:30:00",
  "processes": [
    {
      "name": "chrome.exe",
      "pid": 1234,
      "cpu": 5.2,
      "mem": 120.5
    }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 设备名称（如 "小明学习电脑"）|
| `os` | string | 否 | 操作系统版本（如 "Windows 11 Pro 24H2"）|
| `cpu_usage` | float | 否 | CPU 使用率（百分比，0-100）|
| `mem_usage` | float | 否 | 内存使用率（百分比，0-100）|
| `boot_time` | string | 否 | 开机时间（格式 `YYYY-MM-DD HH:mm:ss`）|
| `processes` | array | 否 | 当前进程列表（**仅名称和资源占用**，不采集其他信息）|

### processes 元素

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 进程名（含 `.exe` 后缀）|
| `pid` | int | 是 | 进程 ID |
| `cpu` | float | 否 | CPU 使用率（百分比）|
| `mem` | float | 否 | 内存占用（MB）|

## 4. 响应（仅 HTTP 状态码，无 body）

| 状态码 | 含义 | 客户端动作 |
|--------|------|-----------|
| **200** | 接受成功，无关机指令 | 等 180 秒后再上报 |
| **201** | 接受成功，下发关机指令 | 立即执行 `shutdown -s -t 0` |
| **401** | 鉴权失败（格式不合法 / uid 不存在 / uid_key 不匹配 / 未绑定微信 openid）| 停止上报，等待绑定后重试 |
| **429** | 请求过频（间隔 < 120 秒）| 等待后重试（不消耗 last_beat_at）|
| 其他 | 错误 | 等 180 秒后重试 |

### 推荐响应头

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 0
```

> 服务器端**无需返回任何 body 内容**，状态码即语义。
>
> **无有效记录分支**：若 uid / uid_key 格式合法，但 `t_device` 中无该设备的有效记录（uid 不存在 / uid_key 不匹配 / 未绑定微信 openid），服务器仍写入一条 `t_device_log`（审计用），但**不更新** `t_device` 设备状态，并返回 401。

## 5. 频率控制

### 客户端

- 心跳间隔：**180 秒**（hardcode，可在 `BeatIntervalSeconds` 常量修改）
- 收到 429 后**重置 180 秒计时**，不立即重试

### 服务端

- 频率底线：**120 秒**（两次 beat 间隔不得小于此值）
- 频率检查逻辑：当前时间 - `last_beat_at` < 120 秒 → 返回 429
- 429 时**不更新** `last_beat_at`，**不写入** `t_device_log`（防止恶意刷新）

## 6. 关机指令流转

```
家长在公众号发起关机
    ↓
服务器标记 t_device.shutdown_status = 1（待下发）
    ↓
PC 下次 beat 上报
    ↓
服务器检测到 shutdown_status = 1
    ↓
返回 HTTP 201
    ↓
更新 t_device.shutdown_status = 2（已下发）+ 写入 t_device_log.cmd_status = 1
    ↓
PC 客户端执行 shutdown -s -t 0
    ↓
PC 关机
```

## 7. 数据存储建议（服务端）

### `t_device`（设备表）

| 字段 | 类型 | 说明 |
|------|------|------|
| `uid` | CHAR(32) UNIQUE | 设备标识 |
| `uid_key` | CHAR(16) | 鉴权密钥 |
| `name` | VARCHAR(64) | 设备名（来自请求或默认机器名）|
| `os` | VARCHAR(32) | 操作系统 |
| `status` | TINYINT | 0=离线 1=在线 |
| `shutdown_status` | TINYINT | 0=无 1=待下发 2=已下发 |
| `last_boot_time` | DATETIME | 最后开机时间（客户端上报）|
| `last_beat_at` | DATETIME | 最后心跳时间（用于 120 秒频率检查）|
| `last_ip` | VARCHAR(45) | 最后上报 IP（nginx 透传）|
| `bound_openid` | VARCHAR(64) | 绑定的微信 openid（官方服务器必填）|
| `created_at`, `updated_at` | DATETIME | 时间戳 |

### `t_device_log`（心跳日志，可选）

| 字段 | 类型 | 说明 |
|------|------|------|
| `uid` | CHAR(32) | 设备标识 |
| `name` | VARCHAR(64) | 设备名称（客户端上报）|
| `os` | VARCHAR(32) | 操作系统（客户端上报）|
| `ip` | VARCHAR(45) | 客户端上报 IP |
| `cpu_usage` | DECIMAL(5,2) | CPU 使用率 |
| `mem_usage` | DECIMAL(5,2) | 内存使用率 |
| `boot_time` | DATETIME | 开机时间（客户端上报）|
| `beat_time` | DATETIME | 心跳时间 |
| `cmd_status` | TINYINT | 0=无指令 1=已下发关机 |

## 8. 完整流程示例

```
PC 上电
  ↓
PC 读取 WeikongPC.ini → 拿到 uid + uid_key + ServerUrl
  ↓
PC 每 180 秒 POST /beat（带 X-Uid, X-Uid-Key header）
  ↓
服务器校验：
  1. uid 是否 32 位 hex、uid_key 是否 16 位 → 不合法返回 401
  2. 查 t_device 是否存在有效记录（uid 存在 && 已绑定微信 && uid_key 匹配）
     - 有效记录：写 t_device_log + 更新 t_device + 频率检查
     - 无有效记录：写 t_device_log，不更新 t_device，返回 401
  3. 有效记录时检查 last_beat_at 距今是否 ≥ 120 秒 → 返回 429
  ↓
检测 shutdown_status：
  - 若为 1：返回 201（关机指令）
  - 否则：返回 200（正常）
  ↓
PC 收到响应后：
  - 200：等 180 秒再上报
  - 201：执行 shutdown -s -t 0 后退出
  - 401：停止服务，进程退出
  - 429：等待 180 秒后再上报
```

## 9. 使用官方服务器的前提

若使用官方服务器 `https://weikongpc.com/beat`，需要：

1. ✅ 在微信公众号「微控儿童电脑PC」菜单中选择「绑定」
2. ✅ 用微信扫描浏览器绑定页展示的二维码（或 ini 二维码）
3. ✅ 微信公众号会调用官方接口将 openid 与 uid 关联
4. ✅ 后续家长可通过公众号查询设备状态、远程关机

**自建服务器**无需公众号绑定，只需自行实现第 6 节的状态管理。

## 10. 参考实现

完整客户端参考实现：`csapp_weikongpc_client/cswsv_weikongpc_report/Program.cs`

测试报告（官方 API）：`docs/API_TEST_REPORT.md`（可选）

服务器实现指南：`docs/SERVER_IMPLEMENTATION.md`

## 11. 版本

- v1.2（2026-08-10）：无有效记录（uid 不存在 / key 不匹配 / 未绑定）改为写日志后返回 401
- v1.1（2026-08-10）：新增 name/boot_time 上报字段；401 改为"格式不合法"；无有效记录时仅记日志不更新设备表
- v1.0（2026-08-10）：初始版本，状态码驱动协议

---

🌐 官网：https://weikongpc.com/
📧 公众号：微控儿童电脑PC
📄 协议：MIT License