<#
============================================================
  SCPclear  |  ปรับเครื่องให้ลื่น + ลบ AI / Bloatware / OneDrive
  UI: WPF (ดีไซน์มินิมอล) - พกพาได้ ไม่ต้องติดตั้ง
============================================================
#>

# ---------- บังคับสิทธิ์ Administrator (+ STA สำหรับ WPF) ----------
$admin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -Sta -NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ErrorActionPreference = "Stop"
try {

# ---------- ตรวจสเปก ----------
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$isHDD = $false
try {
    $sysLetter = ($env:SystemDrive).TrimEnd(':')
    $part = Get-Partition -DriveLetter $sysLetter -ErrorAction Stop
    $pd = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Disk -Number $part.DiskNumber).Number }
    if ($pd.MediaType -eq 'HDD' -or $pd.MediaType -eq 'Unspecified') { $isHDD = $true }
} catch { $isHDD = $true }
$diskType = if ($isHDD) { "HDD" } else { "SSD" }

# ---------- XAML ----------
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SCPclear" Height="800" Width="480"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#F4F5F7" FontFamily="Segoe UI">
  <Window.Resources>
    <!-- Toggle switch -->
    <Style x:Key="Toggle" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="track" Width="46" Height="26" CornerRadius="13" Background="#D5D9DF">
              <Border x:Name="knob" Width="20" Height="20" CornerRadius="10" Background="White"
                      HorizontalAlignment="Left" Margin="3,0,0,0">
                <Border.Effect><DropShadowEffect BlurRadius="3" ShadowDepth="0.5" Opacity="0.25"/></Border.Effect>
              </Border>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="track" Property="Background" Value="#3B6EF6"/>
                <Setter TargetName="knob" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="knob" Property="Margin" Value="0,0,3,0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Card -->
    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="White"/>
      <Setter Property="CornerRadius" Value="12"/>
      <Setter Property="BorderBrush" Value="#ECEEF1"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="16,12"/>
      <Setter Property="Margin" Value="0,0,0,9"/>
    </Style>
    <Style x:Key="RowTitle" TargetType="TextBlock">
      <Setter Property="FontSize" Value="13.5"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="#1F2937"/>
    </Style>
    <Style x:Key="RowDesc" TargetType="TextBlock">
      <Setter Property="FontSize" Value="11.5"/>
      <Setter Property="Foreground" Value="#9AA1AC"/>
      <Setter Property="Margin" Value="0,2,0,0"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="Section" TargetType="TextBlock">
      <Setter Property="FontSize" Value="11.5"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Foreground" Value="#AAB0B8"/>
      <Setter Property="Margin" Value="2,14,0,8"/>
    </Style>
    <!-- Chip button -->
    <Style x:Key="Chip" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="#374151"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="White" BorderBrush="#DDE1E6" BorderThickness="1"
                    CornerRadius="9" Padding="14,7">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#EEF1F5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Primary button -->
    <Style x:Key="Primary" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="#3B6EF6" CornerRadius="11" Padding="0,13">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#2E5BE0"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Background" Value="#274FC7"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Background" Value="#A9BEF5"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Mini progress bar -->
    <Style x:Key="MiniBar" TargetType="ProgressBar">
      <Setter Property="Height" Value="6"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Grid>
              <Border Background="#E6E9EE" CornerRadius="3"/>
              <Border x:Name="PART_Track"/>
              <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="#3B6EF6" CornerRadius="3"/>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid Margin="22,20,22,20">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <StackPanel Grid.Row="0">
      <TextBlock Text="SCPclear" FontSize="24" FontWeight="Bold" Foreground="#111827"/>
      <TextBlock x:Name="SpecText" FontSize="12.5" Foreground="#3B6EF6" FontWeight="SemiBold" Margin="0,2,0,0"/>
    </StackPanel>

    <!-- Preset chips -->
    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,14,0,4">
      <Button x:Name="BtnRec"  Content="แนะนำ" Style="{StaticResource Chip}" Margin="0,0,8,0"/>
      <Button x:Name="BtnAll"  Content="เลือกทั้งหมด" Style="{StaticResource Chip}" Margin="0,0,8,0"/>
      <Button x:Name="BtnNone" Content="ล้างทั้งหมด" Style="{StaticResource Chip}"/>
    </StackPanel>

    <!-- Content -->
    <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="0,8,0,0">
      <StackPanel x:Name="Content">
        <TextBlock Text="ปรับความเร็ว" Style="{StaticResource Section}"/>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="สร้าง Restore Point ก่อน" Style="{StaticResource RowTitle}"/><TextBlock Text="จุดสำรองไว้ย้อนกลับได้ถ้ามีปัญหา" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_restore" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ตั้ง Virtual Memory ให้เหมาะกับแรม" Style="{StaticResource RowTitle}"/><TextBlock Text="ระบบคำนวณค่าให้อัตโนมัติตามแรม" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_pagefile" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ปรับ Visual Effects เน้นความเร็ว" Style="{StaticResource RowTitle}"/><TextBlock Text="ปิดเอฟเฟกต์ที่กินทรัพยากร" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_visual" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ปิด Transparency (ความโปร่งใส)" Style="{StaticResource RowTitle}"/><TextBlock Text="ลดภาระการ์ดจอ" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_transp" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ปิด SysMain (SuperFetch)" Style="{StaticResource RowTitle}"/><TextBlock Text="ตัวการทำให้ HDD ทำงาน 100%" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_sysmain" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ล้างไฟล์ Temp / ขยะ" Style="{StaticResource RowTitle}"/><TextBlock Text="ลบไฟล์ชั่วคราว ปลอดภัย" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_temp" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ล้าง Windows Update cache" Style="{StaticResource RowTitle}"/><TextBlock Text="คืนพื้นที่ดิสก์" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_wucache" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="Power Plan = High Performance" Style="{StaticResource RowTitle}"/><TextBlock Text="โน้ตบุ๊กจะเปลืองแบตขึ้น" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_power" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="Defrag ไดรฟ์ C (เฉพาะ HDD)" Style="{StaticResource RowTitle}"/><TextBlock Text="ข้ามอัตโนมัติถ้าเป็น SSD" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_defrag" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="เปิดหน้าจัดการ Startup ให้ปิดเอง" Style="{StaticResource RowTitle}"/><TextBlock Text="เปิด Task Manager แท็บ Startup ตอนจบ" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_startup" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>

        <TextBlock Text="ลบ AI / BLOATWARE / ความเป็นส่วนตัว" Style="{StaticResource Section}"/>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ถามยืนยันก่อนลบแต่ละอย่าง" Style="{StaticResource RowTitle}"/><TextBlock Text="เด้งถาม Yes/No ก่อนลบทีละตัว (ปลอดภัย)" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_confirm" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ลบ Windows AI (Copilot + Recall)" Style="{StaticResource RowTitle}"/><TextBlock Text="ปิด/ลบ Copilot และ Recall ออกจากเครื่อง" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_removeai" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ลบ Bloatware (Xbox, News ฯลฯ)" Style="{StaticResource RowTitle}"/><TextBlock Text="ลบแอปที่ไม่จำเป็น (ไม่มีในเครื่องจะข้ามให้)" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_bloat" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ปิด Telemetry (ส่งข้อมูลกลับ MS)" Style="{StaticResource RowTitle}"/><TextBlock Text="ปิดการเก็บ/ส่งข้อมูลการใช้งาน" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_telemetry" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center" IsChecked="True"/></Grid></Border>
        <Border Style="{StaticResource Card}"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel VerticalAlignment="Center"><TextBlock Text="ถอนการติดตั้ง OneDrive" Style="{StaticResource RowTitle}"/><TextBlock Text="ปิด+ถอน OneDrive (ไฟล์ยังอยู่ ลงกลับได้)" Style="{StaticResource RowDesc}"/></StackPanel><CheckBox x:Name="cb_onedrive" Grid.Column="1" Style="{StaticResource Toggle}" VerticalAlignment="Center"/></Grid></Border>
      </StackPanel>
    </ScrollViewer>

    <!-- Progress + log -->
    <StackPanel Grid.Row="3" Margin="0,10,0,10">
      <ProgressBar x:Name="Pb" Style="{StaticResource MiniBar}" Minimum="0" Maximum="14" Value="0"/>
      <Border Background="#FBFBFC" BorderBrush="#ECEEF1" BorderThickness="1" CornerRadius="9" Margin="0,10,0,0">
        <TextBox x:Name="Log" IsReadOnly="True" BorderThickness="0" Background="Transparent"
                 Foreground="#556072" FontFamily="Consolas" FontSize="11" Height="92"
                 VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Padding="10,8"/>
      </Border>
    </StackPanel>

    <!-- Run -->
    <Button Grid.Row="4" x:Name="BtnRun" Content="เริ่มทำงาน" Style="{StaticResource Primary}"/>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# ---------- อ้างอิงคอนโทรล ----------
$keys = @("restore","pagefile","visual","transp","sysmain","temp","wucache","power","defrag","startup","confirm","removeai","bloat","telemetry","onedrive")
$checkboxes = @{}
foreach($k in $keys){ $checkboxes[$k] = $window.FindName("cb_$k") }
$SpecText = $window.FindName("SpecText")
$Pb  = $window.FindName("Pb")
$Log = $window.FindName("Log")
$BtnRun  = $window.FindName("BtnRun")
$BtnRec  = $window.FindName("BtnRec")
$BtnAll  = $window.FindName("BtnAll")
$BtnNone = $window.FindName("BtnNone")

$SpecText.Text = "RAM $ramGB GB   •   ไดรฟ์ C = $diskType"
$checkboxes["sysmain"].IsChecked = $isHDD
$checkboxes["defrag"].IsChecked  = $isHDD

# ---------- helper ----------
function Flush-UI { $window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Render, [action]{}) }
function Write-Log($m){ $Log.AppendText("$m`r`n"); $Log.ScrollToEnd(); Flush-UI }
function Step { if($Pb.Value -lt $Pb.Maximum){ $Pb.Value++ }; Flush-UI }
function Set-Reg($path,$name,$value){
    if(-not(Test-Path $path)){ New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}
function Confirm-Remove($name){
    if(-not $checkboxes["confirm"].IsChecked){ return $true }
    $r=[System.Windows.MessageBox]::Show("ต้องการลบ / ปิด:`n`n$name ?","ยืนยัน",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
    return ($r -eq [System.Windows.MessageBoxResult]::Yes)
}

# ---------- presets ----------
$BtnAll.Add_Click({  foreach($k in $keys){ $checkboxes[$k].IsChecked=$true } })
$BtnNone.Add_Click({ foreach($k in $keys){ $checkboxes[$k].IsChecked=$false } })
$BtnRec.Add_Click({
    $rec=@{restore=$true;pagefile=$true;visual=$true;transp=$true;sysmain=$isHDD;temp=$true;wucache=$true;power=$true;defrag=$isHDD;startup=$true;confirm=$true;removeai=$true;bloat=$true;telemetry=$true;onedrive=$false}
    foreach($k in $keys){ $checkboxes[$k].IsChecked=$rec[$k] }
})

# ============================================================
#   การทำงานจริง
# ============================================================
$BtnRun.Add_Click({
  $BtnRun.IsEnabled=$false; $BtnRun.Content="กำลังทำงาน..."
  $Log.Clear(); $Pb.Value=0
  Write-Log ">> เริ่มทำงาน..."
  $ErrorActionPreference="Continue"

  if($checkboxes["restore"].IsChecked){
    try{ Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
         Checkpoint-Computer -Description "SCPclear" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
         Write-Log "[OK] สร้าง Restore Point แล้ว" }
    catch{ Write-Log "[!] สร้าง Restore Point ไม่ได้ (ข้าม)" }
  }; Step

  if($checkboxes["pagefile"].IsChecked){
    try{
      if($ramGB -le 4){ $init=6144; $max=8192 } elseif($ramGB -le 8){ $init=8192; $max=12288 } else{ $init=8192; $max=16384 }
      $cs=Get-CimInstance Win32_ComputerSystem
      if($cs.AutomaticManagedPagefile){ Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$false} }
      $pf=Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
      if($pf){ Set-CimInstance -InputObject $pf -Property @{InitialSize=$init;MaximumSize=$max} }
      else{ New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="$env:SystemDrive\pagefile.sys";InitialSize=$init;MaximumSize=$max} -ErrorAction SilentlyContinue | Out-Null }
      Write-Log "[OK] ตั้ง Virtual Memory = $init - $max MB"
    }catch{ Write-Log "[!] ตั้ง Virtual Memory ไม่สำเร็จ" }
  }; Step

  if($checkboxes["visual"].IsChecked){
    try{ $vfx="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
         if(-not(Test-Path $vfx)){ New-Item -Path $vfx -Force | Out-Null }
         Set-ItemProperty -Path $vfx -Name "VisualFXSetting" -Value 2 -Type DWord
         Write-Log "[OK] ปรับ Visual Effects แล้ว" }
    catch{ Write-Log "[!] Visual Effects ไม่สำเร็จ" }
  }; Step

  if($checkboxes["transp"].IsChecked){
    try{ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord
         Write-Log "[OK] ปิด Transparency แล้ว" }
    catch{ Write-Log "[!] ปิด Transparency ไม่สำเร็จ" }
  }; Step

  if($checkboxes["sysmain"].IsChecked){
    try{ Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
         Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Stop
         Write-Log "[OK] ปิด SysMain แล้ว" }
    catch{ Write-Log "[!] ปิด SysMain ไม่สำเร็จ" }
  }; Step

  if($checkboxes["temp"].IsChecked){
    try{ Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
         Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
         Write-Log "[OK] ล้างไฟล์ Temp แล้ว" }
    catch{ Write-Log "[!] ล้าง Temp บางไฟล์ไม่ได้" }
  }; Step

  if($checkboxes["wucache"].IsChecked){
    try{ Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
         Stop-Service -Name "bits" -Force -ErrorAction SilentlyContinue
         Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
         Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
         Start-Service -Name "bits" -ErrorAction SilentlyContinue
         Write-Log "[OK] ล้าง Windows Update cache แล้ว" }
    catch{ Write-Log "[!] ล้าง Update cache ไม่สำเร็จ" }
  }; Step

  if($checkboxes["power"].IsChecked){
    try{ powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
         Write-Log "[OK] Power Plan = High Performance" }
    catch{ Write-Log "[!] ตั้ง Power Plan ไม่สำเร็จ" }
  }; Step

  if($checkboxes["defrag"].IsChecked){
    if($isHDD){
      try{ Write-Log "[..] กำลัง Defrag ไดรฟ์ C..."
           Optimize-Volume -DriveLetter ($env:SystemDrive.TrimEnd(':')) -Defrag -ErrorAction Stop
           Write-Log "[OK] Defrag เสร็จแล้ว" }
      catch{ Write-Log "[!] Defrag ไม่สำเร็จ" }
    }else{ Write-Log "[i] ข้าม Defrag (เป็น SSD)" }
  }; Step

  if($checkboxes["removeai"].IsChecked){
    if(Confirm-Remove "Windows Copilot"){
      try{ Get-AppxPackage -AllUsers "*Copilot*" | Remove-AppxPackage -ErrorAction SilentlyContinue
           Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*Copilot*" } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue } | Out-Null
           Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
           Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
           Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0
           Write-Log "[OK] ปิด/ลบ Copilot แล้ว" }
      catch{ Write-Log "[!] Copilot ผิดพลาด" }
    }else{ Write-Log "[ข้าม] Copilot" }
    if(Confirm-Remove "Windows Recall"){
      try{ Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart -ErrorAction SilentlyContinue | Out-Null
           Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
           Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
           Write-Log "[OK] ปิด Recall แล้ว" }
      catch{ Write-Log "[!] Recall ผิดพลาด" }
    }else{ Write-Log "[ข้าม] Recall" }
  }; Step

  if($checkboxes["bloat"].IsChecked){
    $bloatApps=@(
      @{N="Xbox (เกม)";P="*Xbox*"},
      @{N="Bing News (ข่าว)";P="Microsoft.BingNews"},
      @{N="Bing Weather (อากาศ)";P="Microsoft.BingWeather"},
      @{N="Solitaire (เกมไพ่)";P="*SolitaireCollection*"},
      @{N="Maps (แผนที่)";P="Microsoft.WindowsMaps"},
      @{N="Clipchamp (ตัดต่อวิดีโอ)";P="Clipchamp.Clipchamp"},
      @{N="People (รายชื่อผู้ติดต่อ)";P="Microsoft.People"},
      @{N="To Do (สิ่งที่ต้องทำ)";P="Microsoft.Todos"},
      @{N="Power Automate";P="Microsoft.PowerAutomateDesktop"},
      @{N="Office Hub";P="Microsoft.MicrosoftOfficeHub"},
      @{N="Get Help (ขอความช่วยเหลือ)";P="Microsoft.GetHelp"},
      @{N="Feedback Hub";P="Microsoft.WindowsFeedbackHub"}
    )
    foreach($a in $bloatApps){
      $exist = Get-AppxPackage -AllUsers $a.P -ErrorAction SilentlyContinue
      if(-not $exist){ continue }
      if(Confirm-Remove $a.N){
        try{ Get-AppxPackage -AllUsers $a.P | Remove-AppxPackage -ErrorAction SilentlyContinue
             Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $a.P } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue } | Out-Null
             Write-Log "[OK] ลบ $($a.N)" }
        catch{ Write-Log "[!] $($a.N) ลบไม่ได้" }
      }else{ Write-Log "[ข้าม] $($a.N)" }
    }
  }; Step

  if($checkboxes["telemetry"].IsChecked){
    if(Confirm-Remove "ปิด Telemetry (การส่งข้อมูลกลับ Microsoft)"){
      try{ Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
           Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
           Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
           Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
           Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "Microsoft Compatibility Appraiser" -ErrorAction SilentlyContinue | Out-Null
           Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Consolidator" -ErrorAction SilentlyContinue | Out-Null
           Write-Log "[OK] ปิด Telemetry แล้ว" }
      catch{ Write-Log "[!] Telemetry ผิดพลาด" }
    }else{ Write-Log "[ข้าม] Telemetry" }
  }; Step

  if($checkboxes["onedrive"].IsChecked){
    if(Confirm-Remove "OneDrive (ถอนการติดตั้ง)"){
      try{ Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
           $od64="$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
           $od32="$env:SystemRoot\System32\OneDriveSetup.exe"
           if(Test-Path $od64){ Start-Process $od64 "/uninstall" -Wait -ErrorAction SilentlyContinue }
           elseif(Test-Path $od32){ Start-Process $od32 "/uninstall" -Wait -ErrorAction SilentlyContinue }
           Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
           Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
           Write-Log "[OK] ถอน OneDrive แล้ว" }
      catch{ Write-Log "[!] OneDrive ผิดพลาด" }
    }else{ Write-Log "[ข้าม] OneDrive" }
  }; Step

  $Pb.Value=$Pb.Maximum
  Write-Log ">> เสร็จเรียบร้อย! แนะนำให้รีสตาร์ทเครื่อง"
  if($checkboxes["startup"].IsChecked){ Write-Log ">> เปิด Task Manager แท็บ Startup..."; Start-Process "taskmgr.exe" "/0 /startup" }
  [System.Windows.MessageBox]::Show("เสร็จแล้ว!`n`nแนะนำให้รีสตาร์ทเครื่องเพื่อให้มีผลเต็มที่","เสร็จสิ้น",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
  $BtnRun.IsEnabled=$true; $BtnRun.Content="เริ่มทำงาน"
})

$window.ShowDialog() | Out-Null

}
catch {
    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
    [System.Windows.MessageBox]::Show("เกิดข้อผิดพลาด:`n`n$($_.Exception.Message)","SCPclear - Error") | Out-Null
}
