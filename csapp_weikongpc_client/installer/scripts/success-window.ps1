# ============================================================================
# 寰帶 PC 瀹夎鎴愬姛椤甸潰 (success-window.ps1)
# 鐢?Inno Setup 瀹夎瀹屾垚鍚庤皟鐢紝鏄剧ず涓や釜浜岀淮鐮?+ 鎿嶄綔鎸囧紩
# ============================================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$WechatQrPath,    # 鍏紬鍙蜂簩缁寸爜鍥剧墖璺緞

    [Parameter(Mandatory=$true)]
    [string]$IniQrPath,       # ini 浜岀淮鐮佸浘鐗囪矾寰?
    [string]$IniContent = ""  # ini 鍐呭锛岀敤浜?澶嶅埗"鍔熻兘
)

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

# ----------------------------------------------------------------------------
# XAML 鐣岄潰
# ----------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="寰帶鍎跨鐢佃剳 瀹夎鎴愬姛"
        Width="900" Height="700"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#F5F5F5">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Microsoft YaHei UI"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- 鏍囬 -->
        <Border Grid.Row="0" Background="#4CAF50" Padding="15" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="鉁?瀹夎鎴愬姛锛? Foreground="White" FontSize="24" FontWeight="Bold"/>
                <TextBlock Text="寰帶鍎跨鐢佃剳 宸叉垚鍔熷畨瑁呭苟娉ㄥ唽涓?Windows 鏈嶅姟" Foreground="White" FontSize="13" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>

        <!-- 浜岀淮鐮佸尯鍩?-->
        <Grid Grid.Row="1" Margin="0,20,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="20"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- 鍏紬鍙蜂簩缁寸爜 -->
            <Border Grid.Column="0" Background="White" BorderBrush="#DDD" BorderThickness="1" CornerRadius="5" Padding="15">
                <StackPanel>
                    <TextBlock Text="鈶?鎵爜鍏虫敞鍏紬鍙? FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                    <Border BorderBrush="#EEE" BorderThickness="1" Padding="5" HorizontalAlignment="Center">
                        <Image x:Name="WechatQrImage" Width="240" Height="240" Stretch="Uniform"/>
                    </Border>
                    <TextBlock Text="寰帶鍎跨鐢佃剳PC" FontSize="14" HorizontalAlignment="Center" Margin="0,10,0,0" Foreground="#333"/>
                    <TextBlock Text="寰俊鎼滅储鍏紬鍙蜂篃鍙叧娉? FontSize="11" HorizontalAlignment="Center" Margin="0,5,0,0" Foreground="#999" TextWrapping="Wrap" TextAlignment="Center"/>
                </StackPanel>
            </Border>

            <!-- ini 浜岀淮鐮?-->
            <Border Grid.Column="2" Background="White" BorderBrush="#DDD" BorderThickness="1" CornerRadius="5" Padding="15">
                <StackPanel>
                    <TextBlock Text="鈶?鍏紬鍙疯彍鍗曢€?缁戝畾"" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                    <Border BorderBrush="#EEE" BorderThickness="1" Padding="5" HorizontalAlignment="Center">
                        <Image x:Name="IniQrImage" Width="240" Height="240" Stretch="Uniform"/>
                    </Border>
                    <TextBlock Text="鎵浜岀淮鐮佸叧鑱旇澶? FontSize="14" HorizontalAlignment="Center" Margin="0,10,0,0" Foreground="#333"/>
                    <TextBlock x:Name="IniContentLabel" Text="..." FontSize="10" HorizontalAlignment="Center" Margin="0,5,0,0" Foreground="#999" TextWrapping="Wrap" TextAlignment="Center" MaxWidth="280"/>
                </StackPanel>
            </Border>
        </Grid>

        <!-- ini 鍐呭鏄剧ず + 澶嶅埗 -->
        <Border Grid.Row="2" Background="White" BorderBrush="#DDD" BorderThickness="1" CornerRadius="5" Padding="15" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="璁惧閰嶇疆淇℃伅锛坕ni 鏂囦欢鍐呭锛夛細" FontSize="13" FontWeight="Bold" Margin="0,0,0,8"/>
                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="IniContentBox" Grid.Column="0" IsReadOnly="True" FontFamily="Consolas" FontSize="12"
                             Background="#F8F8F8" BorderBrush="#DDD" Padding="8" Height="80"
                             VerticalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>
                    <Button x:Name="CopyButton" Grid.Column="1" Content="澶嶅埗鍐呭" Width="90" Height="32" Margin="10,0,0,0"
                            VerticalAlignment="Top"/>
                </Grid>
            </Grid>
        </Border>

        <!-- 鎿嶄綔鎻愮ず + 鍏抽棴鎸夐挳 -->
        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <StackPanel Grid.Column="0">
                <TextBlock Text="馃搶 鎿嶄綔姝ラ" FontSize="13" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBlock Text="1. 鐢ㄥ井淇℃壂绗竴涓簩缁寸爜鍏虫敞鍏紬鍙枫€屽井鎺у効绔ョ數鑴慞C銆? FontSize="12" Foreground="#555" Margin="0,2,0,0"/>
                <TextBlock Text="2. 鍦ㄥ叕浼楀彿鑿滃崟涓偣鍑汇€岀粦瀹氥€? FontSize="12" Foreground="#555" Margin="0,2,0,0"/>
                <TextBlock Text="3. 鐢ㄥ井淇℃壂绗簩涓簩缁寸爜瀹屾垚璁惧鍏宠仈" FontSize="12" Foreground="#555" Margin="0,2,0,0"/>
                <TextBlock Text="馃挕 鎻愮ず锛氳寰楀垹闄ゆ瀹夎绋嬪簭锛岄厤缃凡鑷姩淇濆瓨鍒?WeikongPC.ini" FontSize="11" Foreground="#E91E63" Margin="0,8,0,0" FontStyle="Italic"/>
            </StackPanel>

            <Button x:Name="CloseButton" Grid.Column="1" Content="瀹屾垚" Width="120" Height="36" VerticalAlignment="Center"/>
        </Grid>
    </Grid>
</Window>
"@

# ----------------------------------------------------------------------------
# 鍔犺浇 XAML
# ----------------------------------------------------------------------------
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$wechatQrImage = $window.FindName("WechatQrImage")
$iniQrImage = $window.FindName("IniQrImage")
$iniContentBox = $window.FindName("IniContentBox")
$iniContentLabel = $window.FindName("IniContentLabel")
$copyButton = $window.FindName("CopyButton")
$closeButton = $window.FindName("CloseButton")

# 鍔犺浇浜岀淮鐮佸浘鐗?$wechatQrImage.Source = New-Object System.Windows.Media.Imaging.BitmapImage (New-Object System.Uri $WechatQrPath)
$iniQrImage.Source = New-Object System.Windows.Media.Imaging.BitmapImage (New-Object System.Uri $IniQrPath)

# 璁剧疆 ini 鍐呭鏄剧ず
$iniContentBox.Text = $IniContent
# 鏄剧ず绠€鍖栫増锛堢敤浜庝簩缁寸爜涓嬫柟锛?$shortContent = ($IniContent -replace "`r`n", " | ") -replace "os=.*", ""
$iniContentLabel.Text = $shortContent

# ----------------------------------------------------------------------------
# 浜嬩欢澶勭悊
# ----------------------------------------------------------------------------
$copyButton.Add_Click({
    try {
        [System.Windows.Clipboard]::SetText($IniContentBox.Text)
        $copyButton.Content = "鉁?宸插鍒?
        $copyButton.IsEnabled = $false
        Start-Sleep -Seconds 2
        $copyButton.Content = "澶嶅埗鍐呭"
        $copyButton.IsEnabled = $true
    } catch {
        [System.Windows.MessageBox]::Show("澶嶅埗澶辫触: $($_.Exception.Message)", "閿欒", "OK", "Error")
    }
})

$closeButton.Add_Click({
    $window.Close()
})

# 绐楀彛鍏抽棴浜嬩欢锛氳嚜鍔ㄥ仠姝?PowerShell 杩涚▼
$window.Add_Closed({
    [System.Windows.Application]::Current.Shutdown()
})

# ----------------------------------------------------------------------------
# 鏄剧ず绐楀彛
# ----------------------------------------------------------------------------
$app = New-Object System.Windows.Application
$app.Run($window) | Out-Null