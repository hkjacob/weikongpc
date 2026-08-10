# WeikongPC Beat 鍗忚锛坴1.0锛?
PC 瀹㈡埛绔?鈫?鏈嶅姟鍣ㄧ鐨勫績璺充笂鎶ユ帴鍙ｈ鑼冦€?
> 鈿狅笍 **鍏充簬鏈嶅姟鍣ㄥ疄鐜?*
> - 鏈嶅姟鍣ㄧ**瀹屽叏鍙互鑷瀹炵幇**锛堣嚜寤?HTTP 鏈嶅姟鍗冲彲锛?> - 鑻ヤ娇鐢?*瀹樻柟鏈嶅姟鍣?* `https://weikongpc.com/beat`锛屽繀椤诲厛鍏虫敞寰俊鍏紬鍙枫€屽井鎺у効绔ョ數鑴慞C銆嶅苟鍦ㄥ叕浼楀彿鑿滃崟銆岀粦瀹氥€嶄腑鎵爜鍏宠仈璁惧
> - 瀹樻柟鏈嶅姟鍣ㄧ殑寮€婧愮増鏈殏鏈彂甯冿紝鏈崗璁彲渚涚涓夋柟瀹炵幇瀵规帴

---

## 1. 鎺ュ彛鍦板潃

```
POST {ServerUrl}/beat
```

榛樿鏈嶅姟鍣ㄥ湴鍧€锛歚https://weikongpc.com/beat`锛堝彲鍦?`WeikongPC.ini` 鐨?`[server] url` 涓慨鏀癸級

## 2. 閴存潈鏂瑰紡

浣跨敤 HTTP Header 浼犻€掕澶囪韩浠藉嚟璇侊紙**涓嶈鏀惧湪 body 閲?*锛夛細

| Header | 鏍煎紡 | 璇存槑 |
|--------|------|------|
| `X-Uid` | 32 浣?hex锛圫HA-256锛?| 璁惧鍞竴鏍囪瘑 |
| `X-Uid-Key` | 16 浣嶅瓧绗︼紙瀛楁瘝+鏁板瓧锛?| 璁惧瀵嗛挜 |

**鐢熸垚瑙勫垯**锛?
```text
raw = "{CPU 搴忓垪鍙穧|{涓绘澘搴忓垪鍙穧"
uid = SHA256(raw).hex.substring(0, 32)
uid_key = 16 浣嶉殢鏈哄瓧绗︼紙鍘绘帀鏄撴贩瀛楃锛?/O/1/l/I锛?```

CPU 搴忓垪鍙疯幏鍙栵紙PowerShell锛夛細
```powershell
Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty ProcessorId
```

涓绘澘搴忓垪鍙疯幏鍙栵紙PowerShell锛夛細
```powershell
Get-CimInstance Win32_BaseBoard | Select-Object -First 1 -ExpandProperty SerialNumber
```

鈿狅笍 **鍏抽敭绾︽潫**锛?- 鍚屼竴鍙扮數鑴戝繀椤?*濮嬬粓鐢熸垚鐩稿悓鐨?uid**锛圕PU+涓绘澘搴忓垪鍙风ǔ瀹氫笉鍙橈級
- `uid_key` 鐢辨湇鍔″櫒绔敓鎴愶紝**棣栨缁戝畾鍚庡啓鍏?ini 鏂囦欢**锛屽鎴风闇€鎸佷箙淇濆瓨

## 3. 璇锋眰浣擄紙JSON锛?
```json
{
  "os": "Windows 11 Pro 24H2",
  "cpu_usage": 35.50,
  "mem_usage": 62.30,
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

| 瀛楁 | 绫诲瀷 | 蹇呭～ | 璇存槑 |
|------|------|------|------|
| `os` | string | 鍚?| 鎿嶄綔绯荤粺鐗堟湰锛堝 "Windows 11 Pro 24H2"锛墊
| `cpu_usage` | float | 鍚?| CPU 浣跨敤鐜囷紙鐧惧垎姣旓紝0-100锛墊
| `mem_usage` | float | 鍚?| 鍐呭瓨浣跨敤鐜囷紙鐧惧垎姣旓紝0-100锛墊
| `processes` | array | 鍚?| 褰撳墠杩涚▼鍒楄〃锛?*浠呭悕绉板拰璧勬簮鍗犵敤**锛屼笉閲囬泦鍏朵粬淇℃伅锛墊

### processes 鍏冪礌

| 瀛楁 | 绫诲瀷 | 蹇呭～ | 璇存槑 |
|------|------|------|------|
| `name` | string | 鏄?| 杩涚▼鍚嶏紙鍚?`.exe` 鍚庣紑锛墊
| `pid` | int | 鏄?| 杩涚▼ ID |
| `cpu` | float | 鍚?| CPU 浣跨敤鐜囷紙鐧惧垎姣旓級|
| `mem` | float | 鍚?| 鍐呭瓨鍗犵敤锛圡B锛墊

## 4. 鍝嶅簲锛堜粎 HTTP 鐘舵€佺爜锛屾棤 body锛?
| 鐘舵€佺爜 | 鍚箟 | 瀹㈡埛绔姩浣?|
|--------|------|-----------|
| **200** | 鎺ュ彈鎴愬姛锛屾棤鍏虫満鎸囦护 | 绛?180 绉掑悗鍐嶄笂鎶?|
| **201** | 鎺ュ彈鎴愬姛锛屼笅鍙戝叧鏈烘寚浠?| 绔嬪嵆鎵ц `shutdown -s -t 0` |
| **401** | 鏈敞鍐?/ 閴存潈澶辨晥 | 鍋滄涓婃姤锛岃繘绋嬮€€鍑?|
| **429** | 璇锋眰杩囬锛堥棿闅?< 120 绉掞級| 绛夊緟鍚庨噸璇曪紙涓嶆秷鑰?last_beat_at锛墊
| 鍏朵粬 | 閿欒 | 绛?180 绉掑悗閲嶈瘯 |

### 鎺ㄨ崘鍝嶅簲澶?
```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 0
```

> 鏈嶅姟鍣ㄧ**鏃犻渶杩斿洖浠讳綍 body 鍐呭**锛岀姸鎬佺爜鍗宠涔夈€?
## 5. 棰戠巼鎺у埗

### 瀹㈡埛绔?
- 蹇冭烦闂撮殧锛?*180 绉?*锛坔ardcode锛屽彲鍦?`BeatIntervalSeconds` 甯搁噺淇敼锛?- 鏀跺埌 429 鍚?*閲嶇疆 180 绉掕鏃?*锛屼笉绔嬪嵆閲嶈瘯

### 鏈嶅姟绔?
- 棰戠巼搴曠嚎锛?*120 绉?*锛堜袱娆?beat 闂撮殧涓嶅緱灏忎簬姝ゅ€硷級
- 棰戠巼妫€鏌ラ€昏緫锛氬綋鍓嶆椂闂?- `last_beat_at` < 120 绉?鈫?杩斿洖 429
- 429 鏃?*涓嶆洿鏂?* `last_beat_at`锛?*涓嶅啓鍏?* `t_device_log`锛堥槻姝㈡伓鎰忓埛鏂帮級

## 6. 鍏虫満鎸囦护娴佽浆

```
瀹堕暱鍦ㄥ叕浼楀彿鍙戣捣鍏虫満
    鈫?鏈嶅姟鍣ㄦ爣璁?t_device.shutdown_status = 1锛堝緟涓嬪彂锛?    鈫?PC 涓嬫 beat 涓婃姤
    鈫?鏈嶅姟鍣ㄦ娴嬪埌 shutdown_status = 1
    鈫?杩斿洖 HTTP 201
    鈫?鏇存柊 t_device.shutdown_status = 2锛堝凡涓嬪彂锛? 鍐欏叆 t_device_log.cmd_status = 1
    鈫?PC 瀹㈡埛绔墽琛?shutdown -s -t 0
    鈫?PC 鍏虫満
```

## 7. 鏁版嵁瀛樺偍寤鸿锛堟湇鍔＄锛?
### `t_device`锛堣澶囪〃锛?
| 瀛楁 | 绫诲瀷 | 璇存槑 |
|------|------|------|
| `uid` | CHAR(32) UNIQUE | 璁惧鏍囪瘑 |
| `uid_key` | CHAR(16) | 閴存潈瀵嗛挜 |
| `name` | VARCHAR(64) | 璁惧鍚嶏紙鏉ヨ嚜璇锋眰鎴栭粯璁ゆ満鍣ㄥ悕锛墊
| `os` | VARCHAR(32) | 鎿嶄綔绯荤粺 |
| `status` | TINYINT | 0=绂荤嚎 1=鍦ㄧ嚎 |
| `shutdown_status` | TINYINT | 0=鏃?1=寰呬笅鍙?2=宸蹭笅鍙?|
| `last_beat_at` | DATETIME | 鏈€鍚庡績璺虫椂闂达紙鐢ㄤ簬 120 绉掗鐜囨鏌ワ級|
| `last_ip` | VARCHAR(45) | 鏈€鍚庝笂鎶?IP锛坣ginx 閫忎紶锛墊
| `bound_openid` | VARCHAR(64) | 缁戝畾鐨勫井淇?openid锛堝畼鏂规湇鍔″櫒蹇呭～锛墊
| `created_at`, `updated_at` | DATETIME | 鏃堕棿鎴?|

### `t_device_log`锛堝績璺虫棩蹇楋紝鍙€夛級

| 瀛楁 | 绫诲瀷 | 璇存槑 |
|------|------|------|
| `uid` | CHAR(32) | 璁惧鏍囪瘑 |
| `cpu_usage` | DECIMAL(5,2) | CPU 浣跨敤鐜?|
| `mem_usage` | DECIMAL(5,2) | 鍐呭瓨浣跨敤鐜?|
| `beat_time` | DATETIME | 蹇冭烦鏃堕棿 |
| `cmd_status` | TINYINT | 0=鏃犳寚浠?1=宸蹭笅鍙戝叧鏈?|

## 8. 瀹屾暣娴佺▼绀轰緥

```
PC 涓婄數
  鈫?PC 璇诲彇 WeikongPC.ini 鈫?鎷垮埌 uid + uid_key + ServerUrl
  鈫?PC 姣?180 绉?POST /beat锛堝甫 X-Uid, X-Uid-Key header锛?  鈫?鏈嶅姟鍣ㄦ牎楠岋細
  1. uid 鏍煎紡鏄惁 32 浣?hex
  2. uid 鏄惁鍦?t_device 涓瓨鍦?  3. uid_key 鏄惁鍖归厤
  4. last_beat_at 璺濅粖鏄惁 鈮?120 绉?  鈫?鍐欏叆 t_device_log + 鏇存柊 t_device
  鈫?妫€娴?shutdown_status锛?  - 鑻ヤ负 1锛氳繑鍥?201锛堝叧鏈烘寚浠わ級
  - 鍚﹀垯锛氳繑鍥?200锛堟甯革級
  鈫?PC 鏀跺埌鍝嶅簲鍚庯細
  - 200锛氱瓑 180 绉掑啀涓婃姤
  - 201锛氭墽琛?shutdown -s -t 0 鍚庨€€鍑?  - 401锛氬仠姝㈡湇鍔★紝杩涚▼閫€鍑?  - 429锛氱瓑寰?180 绉掑悗鍐嶄笂鎶?```

## 9. 浣跨敤瀹樻柟鏈嶅姟鍣ㄧ殑鍓嶆彁

鑻ヤ娇鐢ㄥ畼鏂规湇鍔″櫒 `https://weikongpc.com/beat`锛岄渶瑕侊細

1. 鉁?鍦ㄥ井淇″叕浼楀彿銆屽井鎺у効绔ョ數鑴慞C銆嶈彍鍗曚腑閫夋嫨銆岀粦瀹氥€?2. 鉁?鐢ㄥ井淇℃壂鎻忓畨瑁呯▼搴忓睍绀虹殑 ini 浜岀淮鐮?3. 鉁?寰俊鍏紬鍙蜂細璋冪敤瀹樻柟鎺ュ彛灏?openid 涓?uid 鍏宠仈
4. 鉁?鍚庣画瀹堕暱鍙€氳繃鍏紬鍙锋煡璇㈣澶囩姸鎬併€佽繙绋嬪叧鏈?
**鑷缓鏈嶅姟鍣?*鏃犻渶鍏紬鍙风粦瀹氾紝鍙渶鑷瀹炵幇绗?6 鑺傜殑鐘舵€佺鐞嗐€?
## 10. 鍙傝€冨疄鐜?
瀹屾暣瀹㈡埛绔弬鑰冨疄鐜帮細`csapp_weikongpc_client/cswsv_weikongpc_report/Program.cs`

娴嬭瘯鎶ュ憡锛堝畼鏂?API锛夛細`docs/API_TEST_REPORT.md`锛堝彲閫夛級

鏈嶅姟鍣ㄥ疄鐜版寚鍗楋細`docs/SERVER_IMPLEMENTATION.md`

## 11. 鐗堟湰

- v1.0锛?026-08-10锛夛細鍒濆鐗堟湰锛岀姸鎬佺爜椹卞姩鍗忚

---

馃寪 瀹樼綉锛歨ttps://weikongpc.com/
馃摟 鍏紬鍙凤細寰帶鍎跨鐢佃剳PC
馃搫 鍗忚锛歁IT License