# WeikongPC 服务器端实现指南

> 本文档面向**自建服务器**的开发者，介绍如何实现 WeikongPC beat 协议的服务器端。
>
> 如果使用官方服务器（https://weikongpc.com/beat），**无需阅读本文档**。

## 1. 协议依赖

服务器端需要实现：

- ✅ HTTP `POST /beat` 接口（详见 [BEAT_PROTOCOL.md](./BEAT_PROTOCOL.md)）
- ✅ 设备身份管理（uid + uid_key 校验）
- ✅ 频率控制（120 秒底线）
- ✅ 状态码响应（200 / 201 / 401 / 429）
- ⏳ 设备注册机制（首次如何把 uid 加入数据库）

> 官方实现参考（README.md）：项目云端后端（云函数 + MySQL）暂不开源，但接口设计可参考本文档。

## 2. 技术选型

任何能提供 HTTP POST 接口的语言/框架都可以：

| 技术栈 | 难度 | 推荐场景 |
|--------|------|---------|
| **Node.js + Express** | ⭐ | 最简单，5 分钟起步 |
| **Python + Flask/FastAPI** | ⭐ | 数据分析友好 |
| **Go + Gin/Echo** | ⭐⭐ | 高并发，生产环境 |
| **Java + Spring Boot** | ⭐⭐⭐ | 企业级 |
| **PHP + Laravel** | ⭐⭐ | 传统 Web 应用 |
| **C# + ASP.NET** | ⭐⭐ | .NET 生态 |

## 3. 最小实现（Node.js 示例）

```javascript
// server.js
const express = require('express');
const app = express();
app.use(express.json());

// 设备表（实际应该用数据库）
const devices = new Map();

// 注册设备（管理接口，实际应该通过公众号绑定）
app.post('/admin/register', (req, res) => {
    const { uid, uid_key, name } = req.body;
    devices.set(uid, {
        uid_key,
        name,
        last_beat_at: 0,
        shutdown_status: 0
    });
    res.json({ ok: true });
});

app.post('/beat', (req, res) => {
    const uid = req.headers['x-uid'];
    const uidKey = req.headers['x-uid-key'];
    const now = Date.now();

    // 1. 校验格式
    if (!uid || !/^[a-f0-9]{32}$/.test(uid)) {
        return res.status(401).send();
    }
    if (!uidKey || uidKey.length !== 16) {
        return res.status(401).send();
    }

    // 2. 校验设备存在
    const device = devices.get(uid);
    if (!device) {
        return res.status(401).send();
    }

    // 3. 校验密钥
    if (device.uid_key !== uidKey) {
        return res.status(401).send();
    }

    // 4. 频率检查（120 秒底线）
    const elapsed = (now - device.last_beat_at) / 1000;
    if (elapsed < 120) {
        return res.status(429).send();
    }

    // 5. 更新 last_beat_at
    device.last_beat_at = now;

    // 6. 检查关机指令
    if (device.shutdown_status === 1) {
        device.shutdown_status = 2;  // 标记已下发
        return res.status(201).send();
    }

    // 7. 正常返回
    return res.status(200).send();
});

app.listen(8080, () => console.log('Server running on :8080'));
```

## 4. 数据库表设计（MySQL）

```sql
CREATE TABLE t_device (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    uid CHAR(32) NOT NULL UNIQUE,
    uid_key CHAR(16) NOT NULL,
    name VARCHAR(64),
    os VARCHAR(32),
    status TINYINT NOT NULL DEFAULT 0,           -- 0=离线 1=在线
    shutdown_status TINYINT NOT NULL DEFAULT 0,  -- 0=无 1=待下发 2=已下发
    last_beat_at DATETIME,
    last_ip VARCHAR(45),
    bound_openid VARCHAR(64),                    -- 自建可不需要
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_last_beat (last_beat_at),
    INDEX idx_openid (bound_openid)
);

CREATE TABLE t_device_log (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    uid CHAR(32) NOT NULL,
    cpu_usage DECIMAL(5,2),
    mem_usage DECIMAL(5,2),
    beat_time DATETIME NOT NULL,
    cmd_status TINYINT NOT NULL DEFAULT 0,  -- 0=无指令 1=已下发关机
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_uid_beat (uid, beat_time)
);
```

## 5. 关机指令下发接口

服务器端还需要一个内部接口，用于标记设备待关机：

```python
# 示例（Python FastAPI）
@app.post("/internal/shutdown")
def trigger_shutdown(uid: str):
    db.execute(
        "UPDATE t_device SET shutdown_status = 1 WHERE uid = %s",
        (uid,)
    )
    db.commit()
    return {"ok": True}
```

下次 PC 上报时，服务器会返回 201，触发关机。

## 6. 集成到微信小程序（可选）

如果你想让家长通过微信控制电脑，需要：

1. 注册微信服务号，获取 AppID 和 AppSecret
2. 实现 OAuth 2.0 授权（关注公众号后获取 openid）
3. 创建菜单「绑定」和「查询」
4. 「绑定」菜单：用户输入 uid 或扫 ini 二维码，调用 `/bind` 接口关联
5. 「查询」菜单：用户点击后，调用 `/query` 接口返回设备状态
6. 「关机」菜单：用户点击确认后，调用 `/shutdown` 内部接口

> 这部分功能**较为复杂**，建议参考官方服务器的接口设计（暂未开源）。

## 7. 部署建议

### 域名

- 准备一个域名（如 `api.yourdomain.com`）
- 配置 SSL 证书（Let's Encrypt 免费）
- HTTPS 是必须的（HTTP Header 不能跨域被拦截）

### 服务器配置

最低配置：
- CPU: 1 核
- 内存: 512 MB
- 带宽: 1 Mbps（按每 3 分钟 1 次心跳，每条 1KB 计算，1000 台设备仅需 ~5 KB/s）

### 防火墙

放行 80/443 端口（HTTP/HTTPS），其他端口全部关闭。

### 进程管理

推荐用 systemd / pm2 / supervisord 管理 Node.js 进程。

## 8. 安全建议

1. **rate limit**：除 429 之外，对同一 IP 加额外频率限制（如每分钟 100 次）
2. **IP 校验**：检查请求 IP 是否在合理范围（可选）
3. **HTTPS 强制**：客户端强制 HTTPS，明文 HTTP 应拒绝
4. **日志脱敏**：日志中不打印 `X-Uid-Key`，只记录 uid
5. **数据加密**：可选对请求体加密（默认明文 JSON）

## 9. 完整示例项目

### 极简版（30 行）

```bash
# 安装 Node.js 后
npm install express
node server.js
```

### 生产级

建议结构：

```
weikongpc-server/
├── src/
│   ├── routes/
│   │   ├── beat.js          # /beat 接口
│   │   ├── admin.js         # 管理接口
│   │   └── internal.js      # 内部接口（关机指令）
│   ├── middleware/
│   │   ├── auth.js          # 鉴权
│   │   └── ratelimit.js     # 频率限制
│   ├── db/
│   │   ├── mysql.js
│   │   └── redis.js         # 可选，缓存 last_beat_at
│   └── utils/
├── config/
├── tests/
└── docker-compose.yml
```

## 10. 调试技巧

### 模拟客户端请求

```bash
curl -X POST https://yourserver.com/beat \
  -H "X-Uid: bf4f61411effacaa9f69e14398e6598a" \
  -H "X-Uid-Key: cL3l3pD2NGdpI6I9" \
  -H "Content-Type: application/json" \
  -d '{"os":"Windows 11","cpu_usage":50,"mem_usage":60,"processes":[]}' \
  -v
```

预期响应：`200 OK`（空 body）

### 测试 401

```bash
# 用错误 uid_key 测试
curl -X POST ... -H "X-Uid-Key: WRONGKEY12345678" ...
# 预期: 401 Unauthorized
```

### 测试 429

```bash
# 连续两次请求（间隔 < 120 秒）
curl ... & curl ...
# 预期第二次: 429 Too Many Requests
```

## 11. 常见问题

### Q: 客户端用 HTTP 而不是 HTTPS 会怎样？
A: 某些云函数和 CDN 强制 HTTPS，明文 HTTP 可能被拦截或报错。

### Q: 跨域问题（CORS）怎么办？
A: beat 协议由 PC 客户端发起，不是浏览器，**没有 CORS 问题**。

### Q: 需要支持 PC 端主动查询吗？
A: 不需要。客户端只能 push，不能 pull。所有命令通过 beat 的 201 响应下发。

### Q: 客户端能拿到 cmd_id 吗？
A: 当前协议没有 cmd_id 概念。服务器只下发"是否关机"，关机指令本身无参数。如需带参数，可扩展协议。

## 12. 参考链接

- [beat 协议详细规范](./BEAT_PROTOCOL.md)
- 官方客户端源码：`csapp_weikongpc_client/cswsv_weikongpc_report/Program.cs`
- 客户端测试报告：`docs/API_TEST_REPORT.md`（可选）

---

🌐 官网：https://weikongpc.com/
📄 协议：MIT License