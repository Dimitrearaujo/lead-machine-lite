# Lead Machine Lite — Windows Stop
$INSTALL_DIR = "$env:USERPROFILE\.zx-lead-machine"

function Stop-ByPid($label, $pidFile) {
    if (Test-Path $pidFile) {
        $id = [int](Get-Content $pidFile -Raw).Trim()
        $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($proc) {
            Stop-Process -Id $id -Force
            Write-Host "  $label (PID $id) encerrado."
        } else {
            Write-Host "  $label nao estava rodando."
        }
        Remove-Item $pidFile -Force
    } else {
        Write-Host "  $label sem PID registrado."
    }
}

Write-Host "Parando Lead Machine Lite..."
Stop-ByPid "Backend" "$INSTALL_DIR\backend.pid"
Stop-ByPid "Tunnel"  "$INSTALL_DIR\tunnel.pid"
Remove-Item "$INSTALL_DIR\tunnel-url.txt" -Force -ErrorAction SilentlyContinue
Write-Host "Parado."
