# Lead Machine Lite — Windows Start
$INSTALL_DIR = "$env:USERPROFILE\.zx-lead-machine"
$BACKEND_DIR = "$INSTALL_DIR\backend"
$VENV_UVICORN = "$INSTALL_DIR\venv\Scripts\uvicorn.exe"
$LOGS = "$INSTALL_DIR\logs"
$CF_EXE = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Cloudflare.cloudflared_Microsoft.Winget.Source_8wekyb3d8bbwe\cloudflared.exe"

New-Item -ItemType Directory -Force -Path $LOGS | Out-Null
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\zx-leads" | Out-Null

function Kill-ByPidFile($label, $pidFile) {
    if (Test-Path $pidFile) {
        $id = [int](Get-Content $pidFile -Raw).Trim()
        if (Get-Process -Id $id -ErrorAction SilentlyContinue) {
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
            Write-Host "  $label PID $id encerrado"
        }
        Remove-Item $pidFile -Force
    }
}

function Get-PidOnPort($port) {
    $line = netstat -ano | Select-String "127.0.0.1:$port\s.*LISTENING" | Select-Object -First 1
    if (-not $line) {
        $line = netstat -ano | Select-String ":$port\s.*LISTENING" | Select-Object -First 1
    }
    if ($line -and $line.Line -match '\s(\d+)\s*$') { return [int]$Matches[1] }
    return $null
}

Write-Host "[1/4] Parando processos anteriores..."
Kill-ByPidFile "backend" "$INSTALL_DIR\backend.pid"
Kill-ByPidFile "tunnel"  "$INSTALL_DIR\tunnel.pid"
# Mata qualquer processo residual na porta 8792
$oldPid = Get-PidOnPort 8792
if ($oldPid) { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 }
Remove-Item "$INSTALL_DIR\tunnel-url.txt" -Force -ErrorAction SilentlyContinue

Write-Host "[2/4] Subindo backend FastAPI (porta 8792)..."
# Limpa logs anteriores
"" | Out-File "$LOGS\backend.log"    -Encoding utf8
"" | Out-File "$LOGS\backend-err.log" -Encoding utf8

Start-Process -FilePath $VENV_UVICORN `
    -ArgumentList "server:app", "--host", "127.0.0.1", "--port", "8792" `
    -WorkingDirectory $BACKEND_DIR `
    -RedirectStandardOutput "$LOGS\backend.log" `
    -RedirectStandardError  "$LOGS\backend-err.log" `
    -WindowStyle Hidden | Out-Null

# Aguarda backend responder (até 45s) - usa 127.0.0.1 para evitar resolucao IPv6 de localhost
$up = $false
for ($i = 1; $i -le 45; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-RestMethod http://127.0.0.1:8792/health -TimeoutSec 2 -ErrorAction Stop
        if ($r.ok) { $up = $true; break }
    } catch {}
}

if (-not $up) {
    Write-Host "[ERRO] Backend nao respondeu em 45s."
    Write-Host "  Veja: $LOGS\backend-err.log"
    Get-Content "$LOGS\backend-err.log" -Tail 10 | ForEach-Object { Write-Host "  $_" }
    exit 1
}

# Salva o PID real do processo escutando na porta 8792
$realPid = Get-PidOnPort 8792
if ($realPid) {
    "$realPid" | Out-File "$INSTALL_DIR\backend.pid" -Encoding ascii -NoNewline
    Write-Host "       Backend OK (PID $realPid)"
} else {
    Write-Host "       Backend OK (PID nao detectado)"
}

Write-Host "[3/4] Iniciando tunnel cloudflared..."
Set-Content "$LOGS\tunnel.log"     "" -Encoding UTF8
Set-Content "$LOGS\tunnel-out.log" "" -Encoding UTF8

$cfProc = Start-Process -FilePath $CF_EXE `
    -ArgumentList @("tunnel", "--url", "http://localhost:8792", "--no-autoupdate") `
    -RedirectStandardOutput "$LOGS\tunnel-out.log" `
    -RedirectStandardError  "$LOGS\tunnel.log" `
    -WindowStyle Hidden -PassThru
"$($cfProc.Id)" | Out-File "$INSTALL_DIR\tunnel.pid" -Encoding ascii -NoNewline

Write-Host "[4/4] Aguardando URL publica (ate 60s)..."
$url = $null
for ($i = 1; $i -le 60; $i++) {
    Start-Sleep -Seconds 1
    # Usa FileShare.ReadWrite para ler enquanto cloudflared mantém o arquivo aberto
    foreach ($logFile in @("$LOGS\tunnel.log", "$LOGS\tunnel-out.log")) {
        if (-not (Test-Path $logFile)) { continue }
        try {
            $fs = [System.IO.File]::Open($logFile, 'Open', 'Read', 'ReadWrite')
            $reader = [System.IO.StreamReader]::new($fs)
            $content = $reader.ReadToEnd()
            $reader.Close(); $fs.Close()
            $match = [regex]::Match($content, "https://[a-z0-9\-]+\.trycloudflare\.com")
            if ($match.Success) { $url = $match.Value; break }
        } catch {}
    }
    if ($url) { break }
}

if ($url) {
    $url | Out-File "$INSTALL_DIR\tunnel-url.txt" -Encoding ascii -NoNewline
    Write-Host ""
    Write-Host "ZX Lead Machine ativo!" -ForegroundColor Green
    Write-Host "  Backend:    http://localhost:8792"
    Write-Host "  Dashboard:  http://localhost:8792/dashboard"
    Write-Host "  URL Publica: $url" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "[AVISO] Tunnel URL nao capturada em 60s."
    Write-Host "  Backend esta rodando em http://localhost:8792"
    Write-Host "  Verifique: $LOGS\tunnel.log"
}
