# Lead Machine Lite - Windows Status (equivalente ao status.sh do macOS)
$INSTALL_DIR = "$env:USERPROFILE\.zx-lead-machine"
$LOGS = "$INSTALL_DIR\logs"
$LEADS_DIR = "$env:USERPROFILE\zx-leads"

function Check-PidFile($label, $pidFile) {
    if (Test-Path $pidFile) {
        $procId = [int](Get-Content $pidFile -Raw).Trim()
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  $label`t[RODANDO] PID $procId ($($proc.Name))" -ForegroundColor Green
        } else {
            Write-Host "  $label`t[PARADO]  PID $procId nao encontrado" -ForegroundColor Red
        }
    } else {
        Write-Host "  $label`t[PARADO]  sem PID registrado" -ForegroundColor Yellow
    }
}

Write-Host "=== Processos ==="
Check-PidFile "backend" "$INSTALL_DIR\backend.pid"
Check-PidFile "tunnel " "$INSTALL_DIR\tunnel.pid"

Write-Host ""
Write-Host "=== Health ==="
try {
    $r = Invoke-RestMethod http://127.0.0.1:8792/health -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  up  $($r | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "  down  http://localhost:8792/health nao respondeu" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Tunnel URL ==="
if (Test-Path "$INSTALL_DIR\tunnel-url.txt") {
    $url = Get-Content "$INSTALL_DIR\tunnel-url.txt" -Raw
    Write-Host "  $url" -ForegroundColor Cyan
} else {
    Write-Host "  (sem URL salva - tunnel pode estar offline)"
}

Write-Host ""
Write-Host "=== Leads ==="
if (Test-Path $LEADS_DIR) {
    $count = (Get-ChildItem "$LEADS_DIR\*.json" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "  $count lead(s) em $LEADS_DIR"
} else {
    Write-Host "  $LEADS_DIR nao existe"
}

Write-Host ""
Write-Host "=== backend.log (ultimas 10 linhas) ==="
if (Test-Path "$LOGS\backend.log") {
    Get-Content "$LOGS\backend.log" -Tail 10 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  (sem log)"
}

Write-Host ""
Write-Host "=== backend-err.log (ultimas 5 linhas) ==="
if (Test-Path "$LOGS\backend-err.log") {
    Get-Content "$LOGS\backend-err.log" -Tail 5 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  (sem log)"
}
