<#
  เซ็นลายเซ็นดิจิทัล (Authenticode) ให้ SCPclear.exe
  ---------------------------------------------------------------
  แบบที่ 1 (แนะนำถ้าจะแจกคนทั่วไป): ซื้อใบรับรอง Code Signing (.pfx)
           แล้ววางไฟล์ .pfx ไว้ในโฟลเดอร์นี้ สคริปต์จะใช้ไฟล์นั้นเอง
  แบบที่ 2 (ใช้ในองค์กร ฟรี): ถ้าไม่มี .pfx จะสร้างใบรับรองของตัวเอง (self-signed)
           แล้ว export เป็น SCPclear-cert.cer — ต้องติดตั้งใบนี้ในเครื่องที่จะใช้
           (INSTALL-CERT.bat หรือ Group Policy) Windows ถึงจะเชื่อถือลายเซ็น
#>
param(
    [string]$Exe = (Join-Path $PSScriptRoot 'SCPclear.exe'),
    [string]$Subject = 'CN=SCPclear Code Signing',
    [switch]$NoTimestamp
)
$ErrorActionPreference = 'Stop'
try{
    if(-not (Test-Path $Exe)){ throw "ไม่พบไฟล์ $Exe — กด BUILD-EXE.bat ก่อน" }
    $pfx = Get-ChildItem -Path $PSScriptRoot -Filter *.pfx -ErrorAction SilentlyContinue | Select-Object -First 1
    if($pfx){
        Write-Host "ใช้ใบรับรองจากไฟล์: $($pfx.Name)"
        $pw = Read-Host "ใส่รหัสผ่านของไฟล์ .pfx" -AsSecureString
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfx.FullName, $pw, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    } else {
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -eq $Subject -and $_.NotAfter -gt (Get-Date).AddDays(30) } | Sort-Object NotAfter -Descending | Select-Object -First 1
        if($cert){ Write-Host "ใช้ใบรับรองเดิมในเครื่อง: $Subject (หมดอายุ $($cert.NotAfter.ToString('dd/MM/yyyy')))" }
        else {
            Write-Host "ไม่พบไฟล์ .pfx — สร้างใบรับรองสำหรับใช้ในองค์กร: $Subject"
            $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $Subject -CertStoreLocation Cert:\CurrentUser\My `
                        -KeyExportPolicy Exportable -KeyUsage DigitalSignature -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(5)
        }
        $cer = Join-Path $PSScriptRoot 'SCPclear-cert.cer'
        Export-Certificate -Cert $cert -FilePath $cer -Force | Out-Null
        Write-Host "บันทึกใบรับรองสาธารณะ: $cer  (ใช้กับ INSTALL-CERT.bat ในเครื่องอื่น)"
    }

    $sig = $null
    if(-not $NoTimestamp){
        try{ $sig = Set-AuthenticodeSignature -FilePath $Exe -Certificate $cert -HashAlgorithm SHA256 -TimestampServer 'http://timestamp.digicert.com' }
        catch{ Write-Host "ประทับเวลาไม่สำเร็จ (ไม่มีอินเทอร์เน็ต?) — เซ็นแบบไม่มี timestamp แทน" -ForegroundColor Yellow }
    }
    if(-not $sig -or -not $sig.SignerCertificate){ $sig = Set-AuthenticodeSignature -FilePath $Exe -Certificate $cert -HashAlgorithm SHA256 }

    $check = Get-AuthenticodeSignature -FilePath $Exe
    Write-Host ""
    Write-Host "เซ็นแล้ว: $Exe"
    Write-Host "ผู้เซ็น : $($check.SignerCertificate.Subject)"
    if($check.Status -eq 'Valid'){ Write-Host "สถานะ  : Valid (เครื่องนี้เชื่อถือลายเซ็นแล้ว)" -ForegroundColor Green }
    else { Write-Host "สถานะ  : $($check.Status) — ปกติสำหรับใบรับรอง self-signed จนกว่าจะติดตั้ง SCPclear-cert.cer (INSTALL-CERT.bat)" -ForegroundColor Yellow }
}catch{
    Write-Host ("ผิดพลาด: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
