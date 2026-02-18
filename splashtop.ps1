$ErrorActionPreference = 'Stop'

$Url     = "https://www.dropbox.com/scl/fi/youolaff4q0rk6f1ow5oc/Splashtop_Streamer_Windows_DEPLOY_INSTALLER_v3.8.0.4_AXR25ZRHJ7Y4.msi?rlkey=ar3txo7ni5nqm3rcreuidcxmt&st=c7j132sn&dl=1"
$BaseDir = "C:\ProgramData\Supreme\Installers\Splashtop"
$MsiPath = Join-Path $BaseDir "streamer.msi"
$LogDir  = Join-Path $BaseDir "Logs"
$MsiLog  = Join-Path $LogDir  "msi.log"
$RunLog  = Join-Path $LogDir  "run.log"

New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

function Log([string]$m) {
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File -FilePath $RunLog -Append -Encoding utf8
}

try {
  Log "User=$env:USERNAME TEMP=$env:TEMP"
  Log "Downloading -> $MsiPath"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $Url -OutFile $MsiPath -UseBasicParsing

  $msiexec = Join-Path $env:WINDIR "System32\msiexec.exe"
  Log "Using msiexec -> $msiexec"

  $args = "/i `"$MsiPath`" /qn /norestart USERINFO=`"hidewindow=1,confirm_d=0`" /l*v `"$MsiLog`""
  Log "Running -> $msiexec $args"

  $p = Start-Process -FilePath $msiexec -ArgumentList $args -Wait -PassThru
  Log "ExitCode=$($p.ExitCode)"

  exit $p.ExitCode
}
catch {
  Log "ERROR: $($_.Exception.Message)"
  exit 1
}
