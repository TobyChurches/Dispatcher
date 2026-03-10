Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Processes to never close (system-critical or this session)
$Exclude = @(
    'powershell', 'pwsh', 'powershell_ise',
    'cmd', 'conhost', 'WindowsTerminal',
    'explorer',
    'svchost', 'lsass', 'csrss', 'wininit', 'winlogon', 'services',
    'System', 'Idle', 'Registry', 'smss',
    'taskmgr', 'mmc',
    'ApplicationFrameHost', 'TextInputHost'
)

# Only target processes that have a visible window
$targets = Get-Process | Where-Object {
    $_.MainWindowHandle -ne 0 -and
    $Exclude -notcontains $_.ProcessName
}

if (-not $targets) {
    Write-Host "No open applications to close." -ForegroundColor Yellow
    exit 0
}

Write-Host "Closing $($targets.Count) application(s)..." -ForegroundColor Cyan
Write-Host ""

foreach ($proc in $targets) {
    Write-Host "  Closing $($proc.ProcessName)..." -ForegroundColor Yellow
    $closed = $proc.CloseMainWindow()

    if (-not $closed) {
        # CloseMainWindow failed (no message pump) — force stop
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

# Give apps a moment to close gracefully, then force-kill any survivors
Start-Sleep -Seconds 2

foreach ($proc in $targets) {
    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
