# WeikongPC 鏈嶅姟鍣ㄧ瀹炵幇鎸囧崡

> 鏈枃妗ｉ潰鍚?*鑷缓鏈嶅姟鍣?*鐨勫紑鍙戣€咃紝浠嬬粛濡備綍瀹炵幇 WeikongPC beat 鍗忚鐨勬湇鍔″櫒绔€?>
> 濡傛灉浣跨敤瀹樻柟鏈嶅姟鍣紙https://weikongpc.com/beat锛夛紝**鏃犻渶闃呰鏈枃妗?*銆?
## 1. 鍗忚渚濊禆

鏈嶅姟鍣ㄧ闇€瑕佸疄鐜帮細

- 鉁?HTTP `POST /beat` 鎺ュ彛锛堣瑙?[BEAT_PROTOCOL.md](./BEAT_PROTOCOL.md)锛?- 鉁?璁惧韬唤绠＄悊锛坲id + uid_key 鏍￠獙锛?- 鉁?棰戠巼鎺у埗锛?20 绉掑簳绾匡級
- 鉁?鐘舵€佺爜鍝嶅簲锛?00 / 201 / 401 / 429锛?- 鈴?璁惧娉ㄥ唽鏈哄埗锛堥娆″浣曟妸 uid 鍔犲叆鏁版嵁搴擄級

> 瀹樻柟瀹炵幇鍙傝€冿紙README.md锛夛細椤圭洰浜戠鍚庣锛堜簯鍑芥暟 + MySQL锛夋殏涓嶅紑婧愶紝浣嗘帴鍙ｈ璁″彲鍙傝€冩湰鏂囨。銆?
## 2. 鎶€鏈€夊瀷

浠讳綍鑳芥彁渚?HTTP POST 鎺ュ彛鐨勮瑷€/妗嗘灦閮藉彲浠ワ細

| 鎶€鏈爤 | 闅惧害 | 鎺ㄨ崘鍦烘櫙 |
|--------|------|---------|
| **Node.js + Express** | 猸?| 鏈€绠€鍗曪紝5 鍒嗛挓璧锋 |
| **Python + Flask/FastAPI** | 猸?| 鏁版嵁鍒嗘瀽鍙嬪ソ |
| **Go + Gin/Echo** | 猸愨瓙 | 楂樺苟鍙戯紝鐢熶骇鐜 |
| **Java + Spring Boot** | 猸愨瓙猸?| 浼佷笟绾?|
| **PHP + Laravel** | 猸愨瓙 | 浼犵粺 Web 搴旂敤 |
| **C# + ASP.NET** | 猸愨瓙 | .NET 鐢熸€?|

## 3. 鏈€灏忓疄鐜帮紙Node.js 绀轰緥锛?
```javascript
// server.js
const express = require('express');
const app = express();
app.use(express.json());

// 璁惧琛紙瀹為檯搴旇鐢ㄦ暟鎹簱锛?const devices = new Map();

// 娉ㄥ唽璁惧锛堢鐞嗘帴鍙ｏ紝瀹為檯搴旇閫氳繃鍏紬鍙风粦瀹氾級
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

    // 1. 鏍￠獙鏍煎紡
    if (!uid || !/^[a-f0-9]{32}$/.test(uid)) {
        return res.status(401).send();
    }
    if (!uidKey || uidKey.length !== 16) {
        return res.status(401).send();
    }

    // 2. 鏍￠獙璁惧瀛樺湪
    const device = devices.get(uid);
    if (!device) {
        return res.status(401).send();
    }

    // 3. 鏍￠獙瀵嗛挜
    if (device.uid_key !== uidKey) {
        return res.status(401).send();
    }

    // 4. 棰戠巼妫€鏌ワ紙120 绉掑簳绾匡級
    const elapsed = (now - device.last_beat_at) / 1000;
    if (elapsed < 120) {
        return res.status(429).send();
    }

    // 5. 鏇存柊 last_beat_at
    device.last_beat_at = now;

    // 6. 妫€鏌ュ叧鏈烘寚浠?    if (device.shutdown_status === 1) {
        device.shutdown_status = 2;  // 鏍囪宸蹭笅鍙?        return res.status(201).send();
    }

    // 7. 姝ｅ父杩斿洖
    return res.status(200).send();
});

app.listen(8080, () => console.log('Server running on :8080'));
```

## 4. 鏁版嵁搴撹〃璁捐锛圡ySQL锛?
```sql
CREATE TABLE t_device (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    uid CHAR(32) NOT NULL UNIQUE,
    uid_key CHAR(16) NOT NULL,
    name VARCHAR(64),
    os VARCHAR(32),
    status TINYINT NOT NULL DEFAULT 0,           -- 0=绂荤嚎 1=鍦ㄧ嚎
    shutdown_status TINYINT NOT NULL DEFAULT 0,  -- 0=鏃?1=寰呬笅鍙?2=宸蹭笅鍙?    last_beat_at DATETIME,
    last_ip VARCHAR(45),
    bound_openid VARCHAR(64),                    -- 鑷缓鍙笉闇€瑕?    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
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
    cmd_status TINYINT NOT NULL DEFAULT 0,  -- 0=鏃犳寚浠?1=宸蹭笅鍙戝叧鏈?    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_uid_beat (uid, beat_time)
);
```

## 5. 鍏虫満鎸囦护涓嬪彂鎺ュ彛

鏈嶅姟鍣ㄧ杩橀渶瑕佷竴涓唴閮ㄦ帴鍙ｏ紝鐢ㄤ簬鏍囪璁惧寰呭叧鏈猴細

```python
# 绀轰緥锛圥ython FastAPI锛?@app.post("/internal/shutdown")
def trigger_shutdown(uid: str):
    db.execute(
        "UPDATE t_device SET shutdown_status = 1 WHERE uid = %s",
        (uid,)
    )
    db.commit()
    return {"ok": True}
```

涓嬫 PC 涓婃姤鏃讹紝鏈嶅姟鍣ㄤ細杩斿洖 201锛岃Е鍙戝叧鏈恒€?
## 6. 闆嗘垚鍒板井淇″皬绋嬪簭锛堝彲閫夛級

濡傛灉浣犳兂璁╁闀块€氳繃寰俊鎺у埗鐢佃剳锛岄渶瑕侊細

1. 娉ㄥ唽寰俊鏈嶅姟鍙凤紝鑾峰彇 AppID 鍜?AppSecret
2. 瀹炵幇 OAuth 2.0 鎺堟潈锛堝叧娉ㄥ叕浼楀彿鍚庤幏鍙?openid锛?3. 鍒涘缓鑿滃崟銆岀粦瀹氥€嶅拰銆屾煡璇€?4. 銆岀粦瀹氥€嶈彍鍗曪細鐢ㄦ埛杈撳叆 uid 鎴栨壂 ini 浜岀淮鐮侊紝璋冪敤 `/bind` 鎺ュ彛鍏宠仈
5. 銆屾煡璇€嶈彍鍗曪細鐢ㄦ埛鐐瑰嚮鍚庯紝璋冪敤 `/query` 鎺ュ彛杩斿洖璁惧鐘舵€?6. 銆屽叧鏈恒€嶈彍鍗曪細鐢ㄦ埛鐐瑰嚮纭鍚庯紝璋冪敤 `/shutdown` 鍐呴儴鎺ュ彛

> 杩欓儴鍒嗗姛鑳?*杈冧负澶嶆潅**锛屽缓璁弬鑰冨畼鏂规湇鍔″櫒鐨勬帴鍙ｈ璁★紙鏆傛湭寮€婧愶級銆?
## 7. 閮ㄧ讲寤鸿

### 鍩熷悕

- 鍑嗗涓€涓煙鍚嶏紙濡?`api.yourdomain.com`锛?- 閰嶇疆 SSL 璇佷功锛圠et's Encrypt 鍏嶈垂锛?- HTTPS 鏄繀椤荤殑锛圚TTP Header 涓嶈兘璺ㄥ煙琚嫤鎴級

### 鏈嶅姟鍣ㄩ厤缃?
鏈€浣庨厤缃細
- CPU: 1 鏍?- 鍐呭瓨: 512 MB
- 甯﹀: 1 Mbps锛堟寜姣?3 鍒嗛挓 1 娆″績璺筹紝姣忔潯 1KB 璁＄畻锛?000 鍙拌澶囦粎闇€ ~5 KB/s锛?
### 闃茬伀澧?
鏀捐 80/443 绔彛锛圚TTP/HTTPS锛夛紝鍏朵粬绔彛鍏ㄩ儴鍏抽棴銆?
### 杩涚▼绠＄悊

鎺ㄨ崘鐢?systemd / pm2 / supervisord 绠＄悊 Node.js 杩涚▼銆?
## 8. 瀹夊叏寤鸿

1. **rate limit**锛氶櫎 429 涔嬪锛屽鍚屼竴 IP 鍔犻澶栭鐜囬檺鍒讹紙濡傛瘡鍒嗛挓 100 娆★級
2. **IP 鏍￠獙**锛氭鏌ヨ姹?IP 鏄惁鍦ㄥ悎鐞嗚寖鍥达紙鍙€夛級
3. **HTTPS 寮哄埗**锛氬鎴风寮哄埗 HTTPS锛屾槑鏂?HTTP 搴旀嫆缁?4. **鏃ュ織鑴辨晱**锛氭棩蹇椾腑涓嶆墦鍗?`X-Uid-Key`锛屽彧璁板綍 uid
5. **鏁版嵁鍔犲瘑**锛氬彲閫夊璇锋眰浣撳姞瀵嗭紙榛樿鏄庢枃 JSON锛?
## 9. 瀹屾暣绀轰緥椤圭洰

### 鏋佺畝鐗堬紙30 琛岋級

```bash
# 瀹夎 Node.js 鍚?npm install express
node server.js
```

### 鐢熶骇绾?
寤鸿缁撴瀯锛?
```
weikongpc-server/
鈹溾攢鈹€ src/
鈹?  鈹溾攢鈹€ routes/
鈹?  鈹?  鈹溾攢鈹€ beat.js          # /beat 鎺ュ彛
鈹?  鈹?  鈹溾攢鈹€ admin.js         # 绠＄悊鎺ュ彛
鈹?  鈹?  鈹斺攢鈹€ internal.js      # 鍐呴儴鎺ュ彛锛堝叧鏈烘寚浠わ級
鈹?  鈹溾攢鈹€ middleware/
鈹?  鈹?  鈹溾攢鈹€ auth.js          # 閴存潈
鈹?  鈹?  鈹斺攢鈹€ ratelimit.js     # 棰戠巼闄愬埗
鈹?  鈹溾攢鈹€ db/
鈹?  鈹?  鈹溾攢鈹€ mysql.js
鈹?  鈹?  鈹斺攢鈹€ redis.js         # 鍙€夛紝缂撳瓨 last_beat_at
鈹?  鈹斺攢鈹€ utils/
鈹溾攢鈹€ config/
鈹溾攢鈹€ tests/
鈹斺攢鈹€ docker-compose.yml
```

## 10. 璋冭瘯鎶€宸?
### 妯℃嫙瀹㈡埛绔姹?
```bash
curl -X POST https://yourserver.com/beat \
  -H "X-Uid: bf4f61411effacaa9f69e14398e6598a" \
  -H "X-Uid-Key: cL3l3pD2NGdpI6I9" \
  -H "Content-Type: application/json" \
  -d '{"os":"Windows 11","cpu_usage":50,"mem_usage":60,"processes":[]}' \
  -v
```

棰勬湡鍝嶅簲锛歚200 OK`锛堢┖ body锛?
### 娴嬭瘯 401

```bash
# 鐢ㄩ敊璇?uid_key 娴嬭瘯
curl -X POST ... -H "X-Uid-Key: WRONGKEY12345678" ...
# 棰勬湡: 401 Unauthorized
```

### 娴嬭瘯 429

```bash
# 杩炵画涓ゆ璇锋眰锛堥棿闅?< 120 绉掞級
curl ... & curl ...
# 棰勬湡绗簩娆? 429 Too Many Requests
```

## 11. 甯歌闂

### Q: 瀹㈡埛绔敤 HTTP 鑰屼笉鏄?HTTPS 浼氭€庢牱锛?A: 鏌愪簺浜戝嚱鏁板拰 CDN 寮哄埗 HTTPS锛屾槑鏂?HTTP 鍙兘琚嫤鎴垨鎶ラ敊銆?
### Q: 璺ㄥ煙闂锛圕ORS锛夋€庝箞鍔烇紵
A: beat 鍗忚鐢?PC 瀹㈡埛绔彂璧凤紝涓嶆槸娴忚鍣紝**娌℃湁 CORS 闂**銆?
### Q: 闇€瑕佹敮鎸?PC 绔富鍔ㄦ煡璇㈠悧锛?A: 涓嶉渶瑕併€傚鎴风鍙兘 push锛屼笉鑳?pull銆傛墍鏈夊懡浠ら€氳繃 beat 鐨?201 鍝嶅簲涓嬪彂銆?
### Q: 瀹㈡埛绔兘鎷垮埌 cmd_id 鍚楋紵
A: 褰撳墠鍗忚娌℃湁 cmd_id 姒傚康銆傛湇鍔″櫒鍙笅鍙?鏄惁鍏虫満"锛屽叧鏈烘寚浠ゆ湰韬棤鍙傛暟銆傚闇€甯﹀弬鏁帮紝鍙墿灞曞崗璁€?
## 12. 鍙傝€冮摼鎺?
- [beat 鍗忚璇︾粏瑙勮寖](./BEAT_PROTOCOL.md)
- 瀹樻柟瀹㈡埛绔簮鐮侊細`csapp_weikongpc_client/cswsv_weikongpc_report/Program.cs`
- 瀹㈡埛绔祴璇曟姤鍛婏細`docs/API_TEST_REPORT.md`锛堝彲閫夛級

---

馃寪 瀹樼綉锛歨ttps://weikongpc.com/
馃搫 鍗忚锛歁IT License