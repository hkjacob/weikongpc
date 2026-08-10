============================================================
微控儿童电脑 PC 客户端 安装说明
============================================================

【一、文件说明】
本目录包含以下 6 个文件：

  WeikongPC.exe    客户端主程序（Windows 后台服务，约 6 MB）
  install.bat      一键安装（推荐，双击即可）
  install.ps1      安装脚本（也可右键→使用 PowerShell 运行）
  uninstall.bat    一键卸载（推荐，双击即可）
  uninstall.ps1    卸载脚本
  readme.txt       本说明文件

【二、安装步骤】

方法 A（推荐）：双击 install.bat
  1. 双击 install.bat
  2. 弹出「用户账户控制(UAC)」时点击「是」
  3. 自动完成安装，完成后按任意键退出

方法 B：右键 install.ps1 → 使用 PowerShell 运行
  1. 右键 install.ps1 → 选择「使用 PowerShell 运行」
  2. UAC 提示时点击「是」
  3. 自动完成安装

安装脚本会自动完成：
  (1) 将 WeikongPC.exe 复制到 C:\Program Files\WeikongPC\
  (2) 生成设备唯一标识（uid / uid_key）写入 WeikongPC.ini
  (3) 注册 Windows 服务（开机自动启动）
  (4) 启动服务，客户端开始运行
  (5) 等待 5 秒后自动打开浏览器进入设备绑定页面

【三、绑定设备】
  1. 浏览器自动打开 https://weikongpc.com/bind 绑定页面并展示二维码
  2. 使用手机微信「扫一扫」扫描该二维码
  3. 扫码后关注微信公众号「微控儿童电脑PC」即自动完成绑定
  4. 绑定成功后，页面会显示设备名称、系统、IP 等设备信息

【四、注意事项】

1. 必须使用「管理员权限」运行：
   - 双击 .bat 或右键 .ps1 运行时会自动请求管理员权限
   - 如果以普通权限运行，脚本会提示错误并退出

2. 如果 PowerShell 提示「无法加载文件...未进行数字签名」：
   （这是 Windows 的脚本执行策略限制，不是病毒）
   解决方法（任选其一）：
   - 方法 A：直接双击 install.bat（推荐，不受此限制）
   - 方法 B：右键 install.ps1 → 使用 PowerShell 运行
   - 方法 C：在 PowerShell 中先执行下面命令再运行：
       Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   - 方法 D：用命令行绕过：
       powershell -ExecutionPolicy Bypass -File .\install.ps1

3. 首次安装后客户端会收到服务器「未绑定」响应（HTTP 401），
   客户端会自动每 60 秒重试，直到您在微信中完成绑定，无需重启。

4. 如果浏览器没有自动打开绑定页面，可手动打开：
   安装完成后，脚本窗口会显示绑定链接，复制到浏览器访问即可。

5. 系统要求：
   - Windows 10 1607（2016年7月）及以上
   - Windows 11 全版本
   - 需要管理员权限（安装服务）

【五、常见问题】

Q: 运行脚本时提示「禁止运行脚本」？
A: 见上面第 2 点，直接双击 install.bat 即可解决。

Q: 安装后浏览器没有弹出绑定页面？
A: 手动复制脚本输出中的绑定链接到浏览器打开即可。
   该链接格式为：
   https://weikongpc.com/bind?uid=xxx&uid_key=xxx&ts=xxx

Q: 如何确认客户端运行正常？
A: 打开「服务」管理器（Win+R → 输入 services.msc），
   找到「WeikongPC Report Service」，状态应为「正在运行」。
   也可查看 C:\Program Files\WeikongPC\WeikongPC.log 日志文件。

Q: 如何卸载？
A: 双击 uninstall.bat（或右键 uninstall.ps1 → 使用 PowerShell 运行），
   即可停止并删除服务、清理所有文件。

============================================================
官网：https://weikongpc.com/
微信公众号：微控儿童电脑PC
开源仓库：https://github.com/hkjacob/weikongpc
============================================================
