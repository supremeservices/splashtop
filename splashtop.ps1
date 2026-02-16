$ErrorActionPreference = 'Stop'

$DownloadUrl = "https://www.dropbox.com/scl/fi/youolaff4q0rk6f1ow5oc/Splashtop_Streamer_Windows_DEPLOY_INSTALLER_v3.8.0.4_AXR25ZRHJ7Y4.msi?rlkey=ar3txo7ni5nqm3rcreuidcxmt&st=c7j132sn&dl=1"

$BaseDir = "C:\ProgramData\Supreme\Installers\Splashtop"
$Installer = Join-Path $BaseDir "streamer.msi"
$LogDir    = Join-Path $BaseDir "Logs"
$MsiLog    = Join-Path $LogDir "msi.log"
$RunLog    = Join-Path $LogDir "run.log"

New-Item -Path $BaseDir -ItemType Directory -Force | Out-Null
New-Item -Path $LogDir  -ItemType Directory -Force | Out-Null

function Log($m){ (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "  " + $m | Out-File $RunLog -Append -Encoding utf8 }

try {
  Log "Downloading: $DownloadUrl"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $DownloadUrl -OutFile $Installer -UseBasicParsing

  $len = (Get-Item $Installer).Length
  Log "Downloaded size: $len bytes"

  $sig = (Get-Content -Path $Installer -Encoding Byte -TotalCount 8 | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
  Log "File signature (first 8 bytes): $sig"

  $args = @(
    "/i `"$Installer`"",
    "/qn",
    "/norestart",
    "USERINFO=`"hidewindow=1,confirm_d=0`"",
    "/l*v `"$MsiLog`""
  ) -join " "

  Log "Running: msiexec.exe $args"
  $p = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru
  Log "msiexec exit code: $($p.ExitCode)"

  exit $p.ExitCode
}
catch {
  Log "ERROR: $($_.Exception.Message)"
  exit 1
}
