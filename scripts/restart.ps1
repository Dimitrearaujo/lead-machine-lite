# Lead Machine Lite — Windows Restart (equivalente ao restart.sh do macOS)
$INSTALL_DIR = "$env:USERPROFILE\.zx-lead-machine"
Write-Host "Reiniciando Lead Machine Lite..."
. "$INSTALL_DIR\stop.ps1"
Start-Sleep -Seconds 2
. "$INSTALL_DIR\start.ps1"
