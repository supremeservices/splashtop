# Splashtop Streamer deploy: uninstall broken/old installs first, then install
# - Runs as SYSTEM fine
# - Forces 64-bit msiexec (System32)
# - Logs everything to ProgramData\Supreme\Installers\Splashtop\Logs

$ErrorActionPreference = 'Stop'

$Url     = "https://www.dropbox.com/scl/fi/youolaff4q0rk6f1ow5oc/Splashtop_Streamer_Windows_DEPLOY_INSTALLER_v3.8.0.4_AXR25ZRHJ7Y4.msi?rlkey=ar3txo7ni5nqm3rcreuidcxmt&st=c7j132sn&dl=1"
$BaseDir = "C:\ProgramData\Supreme\Installers\Splashtop"
$MsiPath = Join-Path $BaseDir "streamer.msi"
$LogDir  = Join-Path $BaseDir "Logs"
$RunLog  = Join-Path $LogDir  "run.log"
$MsiLog  = Join-Path $LogDir  "msi_install.log"
$UnLog   = Join-Path $LogDir  "msi_uninstall.log"

New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

function Log([string]$m) {
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File -FilePath $RunLog -Append -Encoding utf8
}

function Get-SplashtopProductCodes {
  # Finds MSI ProductCodes (GUIDs) for installed Splashtop entries by reading uninstall registry keys
  $paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  $codes = @()

  foreach ($p in $paths) {
    Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
      Where-Object {
        ($_.DisplayName -and $_.DisplayName -like "*Splashtop*") -or
        ($_.Publisher    -and $_.Publisher    -like "*Splashtop*")
      } |
      ForEach-Object {
        # If the uninstall key name is a GUID, that's usually the ProductCode
        $keyName = $_.PSChildName
        if ($keyName -match '^\{[0-9A-Fa-f\-]{36}\}$') {
          $codes += $keyName
        }
        elseif ($_.UninstallString -match '\{[0-9A-Fa-f\-]{36}\}') {
          $codes += $Matches[0]
        }
      }
  }

  $codes | Sort-Object -Unique
}

try {
  Log "User=$env:USERNAME TEMP=$env:TEMP"
  $msiexec = Join-Path $env:WINDIR "System32\msiexec.exe"
  Log "Using msiexec -> $msiexec"

  # 1) Uninstall any existing Splashtop MSI products (handles broken installs)
  $productCodes = Get-SplashtopProductCodes
  if ($productCodes.Count -gt 0) {
    Log "Found existing Splashtop products: $($productCodes -join ', ')"
    foreach ($code in $productCodes) {
      Log "Uninstalling -> $code"
      $unArgs = "/x $code /qn /norestart /l*v `"$UnLog`""
      $pUn = Start-Process -FilePath $msiexec -ArgumentList $unArgs -Wait -PassThru
      Log "Uninstall exit code for $code -> $($pUn.ExitCode)"
      # 0 = success, 3010 = success/reboot required. Anything else: keep going but log it.
    }
  }
  else {
    Log "No existing Splashtop installation detected."
  }

  # 2) Download MSI (fresh)
  New-Item -Path $BaseDir -ItemType Directory -Force | Out-Null
  Log "Downloading -> $MsiPath"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $Url -OutFile $MsiPath -UseBasicParsing

  # 3) Install
  $args = "/i `"$MsiPath`" /qn /norestart USERINFO=`"hidewindow=1,confirm_d=0`" /l*v `"$MsiLog`""
  Log "Installing -> $msiexec $args"
  $p = Start-Process -FilePath $msiexec -ArgumentList $args -Wait -PassThru
  Log "Install exit code -> $($p.ExitCode)"

  exit $p.ExitCode
}
catch {
  Log "ERROR: $($_.Exception.Message)"
  exit 1
}
