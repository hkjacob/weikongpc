# 寰帶鍎跨鐢佃剳 PC 瀹㈡埛绔?(WeikongPC Client)

> 璁╁闀跨畝鍗曚簡瑙ｅ拰绠＄悊瀛╁瓙浣跨敤鐢佃剳鐨勬儏鍐碉細鐢佃剳鏄惁寮€鏈恒€佺敤浜嗗涔呫€佸繀瑕佹椂鑳藉惁杩滅▼鍏虫満銆?
## 鍏虫敞鍏紬鍙?
<p align="center">
  <img src="csapp_weikongpc_client/docs/assets/wechat-qr.jpg" alt="寰帶鍎跨鐢佃剳PC 寰俊鍏紬鍙? width="200"/>
</p>

鎵爜鍏虫敞寰俊鍏紬鍙枫€?*寰帶鍎跨鐢佃剳PC**銆嶏紝鍦ㄥ叕浼楀彿鑿滃崟涓€夋嫨銆岀粦瀹氥€嶈彍鍗曪紝鎵弿瀹夎绋嬪簭鐢熸垚鐨勮澶囦簩缁寸爜鍗冲彲鍏宠仈璁惧锛屽紑濮嬭繙绋嬬鐞嗗瀛愮殑鐢佃剳銆?
> 鈿狅笍 **濡傛灉浣跨敤瀹樻柟鏈嶅姟鍣?* `https://weikongpc.com/beat`锛?*蹇呴』鍏堢粦瀹氬井淇″叕浼楀彿**銆?> 鑻ヨ嚜寤烘湇鍔″櫒锛屽彲蹇界暐姝ゆ楠わ紙璇﹁ [鏈嶅姟鍣ㄥ疄鐜版寚鍗梋(csapp_weikongpc_client/docs/SERVER_IMPLEMENTATION.md)锛夈€?
## 瀹樼綉

馃寪 **https://weikongpc.com/**

## 椤圭洰鑳屾櫙

寰帶鍎跨鐢佃剳锛圵eikongPC锛夋槸涓€娆捐繍琛屽湪 Windows 鐢佃剳涓婄殑杞婚噺绾у悗鍙版湇鍔＄▼搴忥紝鐢ㄤ簬甯姪瀹堕暱杩滅▼浜嗚В瀛╁瓙鐢佃剳鐨勪娇鐢ㄦ儏鍐碉紝骞跺湪蹇呰鏃惰繙绋嬪叧鏈恒€?
鏈粨搴撲粎鍖呭惈 **PC 瀹㈡埛绔?* 鍜?**瀹夎绋嬪簭** 鐨勬簮浠ｇ爜銆備簯绔悗绔紙浜戝嚱鏁般€佹暟鎹簱銆佸畼缃戯級**鏈紑婧?*锛屼絾鎺ュ彛鍗忚瀹屽叏鍏紑锛屽彲鑷缓鏈嶅姟鍣ㄥ鎺ャ€?
### 鏍稿績鍔熻兘

- 馃枼锔?**鐘舵€侀噰闆?*锛氭瘡 180 绉掗噰闆?CPU 浣跨敤鐜囥€佸唴瀛樹娇鐢ㄧ巼銆佽繘绋嬪垪琛?- 馃摗 **蹇冭烦涓婃姤**锛氶€氳繃 HTTP 涓婃姤鍒颁簯绔紝瀹堕暱鍙疄鏃舵煡鐪嬭澶囩姸鎬?- 馃攲 **杩滅▼鍏虫満**锛氭帴鏀朵簯绔叧鏈烘寚浠わ紝鎵ц姝ｅ父鍏虫満锛堥潪纭柇鐢碉級
- 馃敀 **Session 0 鏈嶅姟**锛氫綔涓?Windows 鍚庡彴鏈嶅姟杩愯锛屽紑鏈鸿嚜鍚紝鏃犵晫闈?- 馃敡 **鑷姩瀹夎**锛氬畨瑁呯▼搴忚嚜鍔ㄧ敓鎴愯澶囪韩浠姐€佹敞鍐屾湇鍔°€佸睍绀虹粦瀹氫簩缁寸爜

### 绯荤粺鏋舵瀯

```
PC 瀹㈡埛绔?(鏈粨搴?          浜戠 (涓嶅湪鏈粨搴?
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?       鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹? WeikongPC.exe  鈹? beat  鈹? 缃戝叧 weikongpc.com
鈹? Session 0 鏈嶅姟  鈹?鈹€鈹€鈹€鈹€鈻?鈹? 浜戝嚱鏁?A (PC 绔?
鈹? 姣?180s 涓婃姤    鈹?鈼勨攢鈹€鈹€  鈹? 浜戝嚱鏁?B (寰俊绔?
鈹? 鎵ц鍏虫満鍛戒护    鈹? 201  鈹? MySQL 鏁版嵁搴?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?       鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                                  鈻?                                  鈹?                           鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                           鈹? 寰俊鍏紬鍙?  鈹?                           鈹? 鍏冨疂鏅鸿兘浣?  鈹?                           鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?```

### 鎶€鏈爤

| 缁勪欢 | 鎶€鏈?| 璇存槑 |
|------|------|------|
| PC 瀹㈡埛绔?| C# .NET 8 + Native AOT | 鍗曟枃浠?exe锛? MB锛屾棤杩愯鏃朵緷璧?|
| 瀹夎绋嬪簭 | Inno Setup 6 + PowerShell | 涓夌妯″紡锛氬畨瑁?淇/鍗歌浇 |
| 璁惧韬唤 | SHA-256 鍝堝笇 | CPU+涓绘澘搴忓垪鍙?鈫?32 浣?uid |
| 閴存潈 | HTTP Header | X-Uid / X-Uid-Key |
| 鍗忚 | 鐘舵€佺爜椹卞姩 | 200 姝ｅ父 / 201 鍏虫満 / 401 澶辫触 / 429 杩囬 |

## 浠撳簱缁撴瀯

```
weikongpc/                                # GitHub 浠撳簱鏍?鈹溾攢鈹€ README.md                            # 鏈枃浠?鈹溾攢鈹€ LICENSE                              # MIT 寮€婧愬崗璁?鈹溾攢鈹€ .gitignore
鈹斺攢鈹€ csapp_weikongpc_client/              # PC 瀹㈡埛绔」鐩?    鈹溾攢鈹€ cswsv_weikongpc_report/          # PC 瀹㈡埛绔簮鐮?    鈹?  鈹溾攢鈹€ Program.cs                   # 鍗曟枃浠跺疄鐜帮紙绾?400 琛岋級
    鈹?  鈹斺攢鈹€ cswsv_weikongpc_report.csproj # 椤圭洰閰嶇疆锛圓OT 缂栬瘧锛?    鈹斺攢鈹€ installer/                       # 瀹夎绋嬪簭
        鈹溾攢鈹€ installer.iss                # Inno Setup 鑴氭湰
        鈹溾攢鈹€ scripts/
        鈹?  鈹溾攢鈹€ setup-helper.ps1         # 纭欢璇嗗埆 + ini 鐢熸垚 + 浜岀淮鐮?        鈹?  鈹斺攢鈹€ success-window.ps1       # WPF 鎴愬姛椤甸潰
        鈹斺攢鈹€ assets/
            鈹溾攢鈹€ LICENSE.txt              # 鐢ㄦ埛鍗忚
            鈹斺攢鈹€ wechat-qr.jpg            # 鍏紬鍙蜂簩缁寸爜
```

## 缂栬瘧

### 鐜瑕佹眰

- .NET 8 SDK (8.0.423+)
- Visual Studio Build Tools 2022锛堝惈 C++ 妗岄潰寮€鍙戝伐浣滆礋杞斤級
- Windows SDK 10.0.26100+
- Inno Setup 6.7+锛堢紪璇戝畨瑁呯▼搴忥級

### 缂栬瘧瀹㈡埛绔?
```powershell
cd csapp_weikongpc_client\cswsv_weikongpc_report
dotnet publish -r win-x64 -c Release
# 浜х墿锛歜in\Release\net8.0-windows\win-x64\publish\WeikongPC.exe (绾?6 MB)
```

### 缂栬瘧瀹夎绋嬪簭

```powershell
cd csapp_weikongpc_client\installer
ISCC.exe installer.iss
# 浜х墿锛歰utput\WeikongPC-Setup-1.0.0.exe (绾?4 MB)
```

## 杩愯

### 瀹夎

鍙屽嚮 `WeikongPC-Setup-1.0.0.exe`锛屾寜鍚戝瀹屾垚瀹夎銆傚畨瑁呯▼搴忎細锛?
1. 澶嶅埗鏂囦欢鍒?`C:\Program Files\WeikongPC\`
2. 鐢熸垚 `WeikongPC.ini`锛堝惈璁惧 uid 鍜?key锛?3. 鐢熸垚璁惧缁戝畾浜岀淮鐮?4. 娉ㄥ唽 Windows 鏈嶅姟锛堝紑鏈鸿嚜鍚級
5. 鏄剧ず鍏紬鍙蜂簩缁寸爜鍜岀粦瀹氫簩缁寸爜

### 鍗歌浇

閫氳繃鎺у埗闈㈡澘 鈫?绋嬪簭鍜屽姛鑳?鈫?鍗歌浇銆?
### 鍛戒护琛?
```cmd
WeikongPC.exe install      :: 娉ㄥ唽涓?Windows 鏈嶅姟锛堥渶绠＄悊鍛橈級
WeikongPC.exe uninstall    :: 娉ㄩ攢 Windows 鏈嶅姟锛堥渶绠＄悊鍛橈級
WeikongPC.exe              :: 鐩存帴杩愯锛堣皟璇曠敤锛孋trl+C 閫€鍑猴級
```

## 鍏煎鎬?
- 鉁?Windows 10 1607 (2016 骞?7 鏈? 鍙婁互涓?- 鉁?Windows 11 鍏ㄧ増鏈?- 鉁?Windows Server 2016/2019/2022/2025
- 鉂?Windows 7锛?NET 8 AOT 涓嶆敮鎸侊級

## 寮€婧愬崗璁?
MIT License - 璇﹁ [LICENSE](LICENSE)

## 鐩稿叧閾炬帴

- 馃寪 瀹樼綉锛歨ttps://weikongpc.com/
- 馃摟 寰俊鍏紬鍙凤細寰帶鍎跨鐢佃剳PC
- 馃 鍏冨疂鏅鸿兘浣擄細閫氳繃鍏紬鍙锋帴鍏?
## 鍗忚鏂囨。

- 馃摗 **[beat 鍗忚瑙勮寖](csapp_weikongpc_client/docs/BEAT_PROTOCOL.md)**锛氬鎴风涓庢湇鍔″櫒绔殑閫氫俊鍗忚锛圚TTP Header 閴存潈 + 鐘舵€佺爜椹卞姩锛?- 馃洜锔?**[鏈嶅姟鍣ㄥ疄鐜版寚鍗梋(csapp_weikongpc_client/docs/SERVER_IMPLEMENTATION.md)**锛氬浣曡嚜寤烘湇鍔″櫒瀵规帴鏈鎴风锛圢ode.js / Python / Go / Java 绛夛級

## 璐＄尞

娆㈣繋鎻愪氦 Issue 鍜?Pull Request銆?
---

漏 2026 weikongpc.com
