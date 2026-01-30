# Download + New Install (clean machine only)

$DownloadUrl = "https://www.dropbox.com/scl/fi/youolaff4q0rk6f1ow5oc/Splashtop_Streamer_Windows_DEPLOY_INSTALLER_v3.8.0.4_AXR25ZRHJ7Y4.msi?rlkey=ar3txo7ni5nqm3rcreuidcxmt&st=c7j132sn&dl=1"
$Installer   = "$env:ProgramData\streamer.msi"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri $DownloadUrl -OutFile $Installer -UseBasicParsing

Start-Process msiexec.exe -ArgumentList "/norestart /qn /i `"$Installer`" USERINFO=`"hidewindow=1,confirm_d=0`"" -Wait
