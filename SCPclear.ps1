<#
============================================================
  PC Booster  |  ปรับเครื่องให้ลื่น + ลบ AI / Bloatware / Telemetry
  - พกพาได้ ไม่ต้องติดตั้ง
  - สร้าง Restore Point ก่อนเสมอ และย้อนกลับได้
============================================================
#>

# ---------- บังคับสิทธิ์ Administrator ----------
$admin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"
try {

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------- สี ----------
$cBg     = [System.Drawing.Color]::FromArgb(28,29,34)
$cCard   = [System.Drawing.Color]::FromArgb(38,39,46)
$cText   = [System.Drawing.Color]::White
$cSub    = [System.Drawing.Color]::FromArgb(155,157,165)
$cAccent = [System.Drawing.Color]::FromArgb(88,166,255)
$cGreen  = [System.Drawing.Color]::FromArgb(56,161,92)
$cGreenH = [System.Drawing.Color]::FromArgb(70,185,110)
$cGray   = [System.Drawing.Color]::FromArgb(70,71,80)

# ---------- ตรวจสเปก ----------
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$isHDD = $false
try {
    $sysLetter = ($env:SystemDrive).TrimEnd(':')
    $part = Get-Partition -DriveLetter $sysLetter -ErrorAction Stop
    $pd = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Disk -Number $part.DiskNumber).Number }
    if ($pd.MediaType -eq 'HDD' -or $pd.MediaType -eq 'Unspecified') { $isHDD = $true }
} catch { $isHDD = $true }
$diskType = if ($isHDD) { "HDD (จานหมุน)" } else { "SSD" }

# ---------- ฟอร์ม ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "SCPclear"
$form.Size = New-Object System.Drawing.Size(600, 820)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $cBg
$form.Font = New-Object System.Drawing.Font("Segoe UI",9)

$tip = New-Object System.Windows.Forms.ToolTip
$tip.AutoPopDelay = 8000; $tip.InitialDelay = 300

# หัวข้อ
$header = New-Object System.Windows.Forms.Label
$header.Text = "SCPclear"
$header.ForeColor = $cText
$header.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$header.Location = New-Object System.Drawing.Point(20,12)
$header.Size = New-Object System.Drawing.Size(300,32)
$form.Controls.Add($header)

$spec = New-Object System.Windows.Forms.Label
$spec.Text = "RAM $ramGB GB   •   ไดรฟ์ C = $diskType"
$spec.ForeColor = $cGreen
$spec.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$spec.Location = New-Object System.Drawing.Point(22,46)
$spec.Size = New-Object System.Drawing.Size(400,22)
$form.Controls.Add($spec)

# ---------- ปุ่มพรีเซ็ต ----------
function New-Preset($text,$x,$w){
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $b.BackColor = $cCard
    $b.ForeColor = $cText
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $cGray
    $b.Location = New-Object System.Drawing.Point($x,78)
    $b.Size = New-Object System.Drawing.Size($w,32)
    $form.Controls.Add($b)
    return $b
}
$btnRec  = New-Preset "แนะนำ (ปลอดภัย)" 20  170
$btnAll  = New-Preset "เลือกทั้งหมด"    198 170
$btnNone = New-Preset "ล้างทั้งหมด"     376 190

# ---------- panel เลื่อนได้ ----------
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(15,120)
$panel.Size = New-Object System.Drawing.Size(555,415)
$panel.AutoScroll = $true
$panel.BackColor = $cBg
$form.Controls.Add($panel)

$checkboxes = @{}
$script:y = 5

function Add-Section($text){
    $bar = New-Object System.Windows.Forms.Panel
    $bar.BackColor = $cCard
    $bar.Location = New-Object System.Drawing.Point(3,$script:y)
    $bar.Size = New-Object System.Drawing.Size(525,32)
    $panel.Controls.Add($bar)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.ForeColor = $cAccent
    $l.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $l.Location = New-Object System.Drawing.Point(10,5)
    $l.Size = New-Object System.Drawing.Size(505,22)
    $bar.Controls.Add($l)
    $script:y += 40
}

function Add-Check($key,$text,$desc,$checked){
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $text
    $cb.Checked = $checked
    $cb.ForeColor = $cText
    $cb.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $cb.Location = New-Object System.Drawing.Point(12,$script:y)
    $cb.Size = New-Object System.Drawing.Size(510,22)
    $panel.Controls.Add($cb)
    $checkboxes[$key] = $cb
    $tip.SetToolTip($cb,$desc)
    $script:y += 22
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $desc
    $lbl.ForeColor = $cSub
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
    $lbl.Location = New-Object System.Drawing.Point(32,$script:y)
    $lbl.Size = New-Object System.Drawing.Size(495,28)
    $panel.Controls.Add($lbl)
    $script:y += 32
}

Add-Section "ปรับความเร็ว"
Add-Check "restore"  "สร้าง Restore Point ก่อน (แนะนำ)" "จุดสำรองไว้ย้อนกลับได้ถ้ามีปัญหา" $true
Add-Check "pagefile" "ตั้ง Virtual Memory ให้เหมาะกับแรม" "ระบบคำนวณค่าให้อัตโนมัติตามแรม" $true
Add-Check "visual"   "ปรับ Visual Effects เน้นความเร็ว" "ปิดเอฟเฟกต์ที่กินทรัพยากร" $true
Add-Check "transp"   "ปิด Transparency (ความโปร่งใส)" "ลดภาระการ์ดจอ" $true
Add-Check "sysmain"  "ปิด SysMain (SuperFetch)" "ตัวการทำให้ HDD ทำงาน 100%" $isHDD
Add-Check "temp"     "ล้างไฟล์ Temp / ขยะ" "ลบไฟล์ชั่วคราว ปลอดภัย" $true
Add-Check "wucache"  "ล้าง Windows Update cache" "คืนพื้นที่ดิสก์" $true
Add-Check "power"    "ตั้ง Power Plan = High Performance" "โน้ตบุ๊กจะเปลืองแบตขึ้น" $true
Add-Check "defrag"   "Defrag ไดรฟ์ C (เฉพาะ HDD)" "ข้ามอัตโนมัติถ้าเป็น SSD" $isHDD
Add-Check "startup"  "เปิดหน้าจัดการ Startup ให้ปิดเอง" "เปิด Task Manager แท็บ Startup ตอนจบ" $true

Add-Section "ลบ AI / Bloatware / ความเป็นส่วนตัว"
Add-Check "confirm"   "ถามยืนยันก่อนลบแต่ละอย่าง (ปลอดภัย)" "จะเด้งถาม Yes/No ก่อนลบทีละตัว" $true
Add-Check "removeai"  "ลบ Windows AI (Copilot + Recall)" "ปิด/ลบ Copilot และ Recall ออกจากเครื่อง" $true
Add-Check "bloat"     "ลบ Bloatware (Xbox, News, ฯลฯ)" "ลบแอปที่ไม่จำเป็น (ถ้าไม่มีในเครื่องจะข้ามให้)" $true
Add-Check "telemetry" "ปิด Telemetry (ส่งข้อมูลกลับ MS)" "ปิดการเก็บ/ส่งข้อมูลการใช้งาน" $true

# ---------- presets ----------
$allKeys = @("restore","pagefile","visual","transp","sysmain","temp","wucache","power","defrag","startup","confirm","removeai","bloat","telemetry")
$btnAll.Add_Click({  foreach($k in $allKeys){ $checkboxes[$k].Checked=$true } })
$btnNone.Add_Click({ foreach($k in $allKeys){ $checkboxes[$k].Checked=$false } })
$btnRec.Add_Click({
    $checkboxes["restore"].Checked=$true;  $checkboxes["pagefile"].Checked=$true
    $checkboxes["visual"].Checked=$true;   $checkboxes["transp"].Checked=$true
    $checkboxes["sysmain"].Checked=$isHDD; $checkboxes["temp"].Checked=$true
    $checkboxes["wucache"].Checked=$true;  $checkboxes["power"].Checked=$true
    $checkboxes["defrag"].Checked=$isHDD;  $checkboxes["startup"].Checked=$true
    $checkboxes["confirm"].Checked=$true;  $checkboxes["removeai"].Checked=$true
    $checkboxes["bloat"].Checked=$true;    $checkboxes["telemetry"].Checked=$true
})

# ---------- progress + log ----------
$pb = New-Object System.Windows.Forms.ProgressBar
$pb.Location = New-Object System.Drawing.Point(20,545)
$pb.Size = New-Object System.Drawing.Size(555,16)
$pb.Minimum = 0; $pb.Maximum = 12; $pb.Value = 0
$form.Controls.Add($pb)

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ScrollBars = "Vertical"
$log.ReadOnly = $true
$log.BackColor = [System.Drawing.Color]::FromArgb(18,19,23)
$log.ForeColor = $cGreen
$log.Font = New-Object System.Drawing.Font("Consolas",9)
$log.Location = New-Object System.Drawing.Point(20,570)
$log.Size = New-Object System.Drawing.Size(555,120)
$form.Controls.Add($log)
function Write-Log($m){ $log.AppendText("$m`r`n"); $log.Refresh() }
function Step { if($pb.Value -lt $pb.Maximum){ $pb.Value++ }; $pb.Refresh() }

# ---------- ปุ่มหลัก ----------
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "เริ่มทำงาน"
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$btnRun.BackColor = $cGreen
$btnRun.ForeColor = $cText
$btnRun.FlatStyle = "Flat"
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Location = New-Object System.Drawing.Point(20,700)
$btnRun.Size = New-Object System.Drawing.Size(410,48)
$btnRun.Add_MouseEnter({ $btnRun.BackColor=$cGreenH })
$btnRun.Add_MouseLeave({ $btnRun.BackColor=$cGreen })
$form.Controls.Add($btnRun)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "ปิด"
$btnExit.Font = New-Object System.Drawing.Font("Segoe UI",11)
$btnExit.BackColor = $cGray
$btnExit.ForeColor = $cText
$btnExit.FlatStyle = "Flat"
$btnExit.FlatAppearance.BorderSize = 0
$btnExit.Location = New-Object System.Drawing.Point(440,700)
$btnExit.Size = New-Object System.Drawing.Size(135,48)
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

# ---------- helper ----------
function Set-Reg($path,$name,$value){
    if(-not(Test-Path $path)){ New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}
function Confirm-Remove($name){
    if(-not $checkboxes["confirm"].Checked){ return $true }
    $r=[System.Windows.Forms.MessageBox]::Show("ต้องการลบ / ปิด:`n`n$name ?","ยืนยัน","YesNo","Question")
    return ($r -eq [System.Windows.Forms.DialogResult]::Yes)
}

# ============================================================
#   การทำงานจริง
# ============================================================
$btnRun.Add_Click({
  $btnRun.Enabled=$false; $btnRun.Text="กำลังทำงาน..."
  $log.Clear(); $pb.Value=0
  Write-Log ">> เริ่มทำงาน..."
  $ErrorActionPreference="Continue"

  if($checkboxes["restore"].Checked){
    try{ Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
         Checkpoint-Computer -Description "SCPclear" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
         Write-Log "[OK] สร้าง Restore Point แล้ว" }
    catch{ Write-Log "[!] สร้าง Restore Point ไม่ได้ (ข้าม)" }
  }; Step

  if($checkboxes["pagefile"].Checked){
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

  if($checkboxes["visual"].Checked){
    try{ $vfx="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
         if(-not(Test-Path $vfx)){ New-Item -Path $vfx -Force | Out-Null }
         Set-ItemProperty -Path $vfx -Name "VisualFXSetting" -Value 2 -Type DWord
         Write-Log "[OK] ปรับ Visual Effects แล้ว" }
    catch{ Write-Log "[!] Visual Effects ไม่สำเร็จ" }
  }; Step

  if($checkboxes["transp"].Checked){
    try{ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord
         Write-Log "[OK] ปิด Transparency แล้ว" }
    catch{ Write-Log "[!] ปิด Transparency ไม่สำเร็จ" }
  }; Step

  if($checkboxes["sysmain"].Checked){
    try{ Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
         Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Stop
         Write-Log "[OK] ปิด SysMain แล้ว" }
    catch{ Write-Log "[!] ปิด SysMain ไม่สำเร็จ" }
  }; Step

  if($checkboxes["temp"].Checked){
    try{ Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
         Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
         Write-Log "[OK] ล้างไฟล์ Temp แล้ว" }
    catch{ Write-Log "[!] ล้าง Temp บางไฟล์ไม่ได้" }
  }; Step

  if($checkboxes["wucache"].Checked){
    try{ Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
         Stop-Service -Name "bits" -Force -ErrorAction SilentlyContinue
         Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
         Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
         Start-Service -Name "bits" -ErrorAction SilentlyContinue
         Write-Log "[OK] ล้าง Windows Update cache แล้ว" }
    catch{ Write-Log "[!] ล้าง Update cache ไม่สำเร็จ" }
  }; Step

  if($checkboxes["power"].Checked){
    try{ powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
         Write-Log "[OK] Power Plan = High Performance" }
    catch{ Write-Log "[!] ตั้ง Power Plan ไม่สำเร็จ" }
  }; Step

  if($checkboxes["defrag"].Checked){
    if($isHDD){
      try{ Write-Log "[..] กำลัง Defrag ไดรฟ์ C..."
           Optimize-Volume -DriveLetter ($env:SystemDrive.TrimEnd(':')) -Defrag -ErrorAction Stop
           Write-Log "[OK] Defrag เสร็จแล้ว" }
      catch{ Write-Log "[!] Defrag ไม่สำเร็จ" }
    }else{ Write-Log "[i] ข้าม Defrag (เป็น SSD)" }
  }; Step

  if($checkboxes["removeai"].Checked){
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

  if($checkboxes["bloat"].Checked){
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

  if($checkboxes["telemetry"].Checked){
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

  $pb.Value=$pb.Maximum
  Write-Log ">> เสร็จเรียบร้อย! แนะนำให้รีสตาร์ทเครื่อง"
  if($checkboxes["startup"].Checked){ Write-Log ">> เปิด Task Manager แท็บ Startup..."; Start-Process "taskmgr.exe" "/0 /startup" }
  [System.Windows.Forms.MessageBox]::Show("เสร็จแล้ว!`n`nแนะนำให้รีสตาร์ทเครื่องเพื่อให้มีผลเต็มที่","เสร็จสิ้น","OK","Information") | Out-Null
  $btnRun.Enabled=$true; $btnRun.Text="เริ่มทำงาน"
})

[void]$form.ShowDialog()

}
catch {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    [System.Windows.Forms.MessageBox]::Show("เกิดข้อผิดพลาด:`n`n$($_.Exception.Message)","SCPclear - Error","OK","Error") | Out-Null
}
