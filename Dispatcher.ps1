<#
.SYNOPSIS
    Dispatcher — runs scripts by group and name.
    Usage: Dispatcher <group> <scriptname> [additional args]

.EXAMPLE
    Dispatcher azure restart-app
    Dispatcher dev clean-build -environment staging
#>

param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ArgumentCompleter({
        param($cmd, $param, $wordToComplete)
        $baseDir = "D:\LocalScripts"
        if (Test-Path $baseDir) {
            Get-ChildItem $baseDir -Directory |
                Where-Object { $_.Name -like "$wordToComplete*" } |
                ForEach-Object { $_.Name }
        }
    })]
    [string]$Group,

    [Parameter(Position = 1, Mandatory = $true)]
    [ArgumentCompleter({
        param($cmd, $param, $wordToComplete, $ast, $fakeBoundParams)
        $baseDir = "D:\LocalScripts"
        $group = $fakeBoundParams['Group']
        if ($group) {
            $groupDir = Join-Path $baseDir $group
            if (Test-Path $groupDir) {
                Get-ChildItem $groupDir -Filter "*.ps1" |
                    Where-Object { $_.BaseName -like "$wordToComplete*" } |
                    ForEach-Object { $_.BaseName }
            }
        }
    })]
    [string]$ScriptName,

    [Parameter(ValueFromRemainingArguments = $true)]
    $RemainingArgs
)

# Strip leading dash if provided (for backwards compatibility)
$ScriptName = $ScriptName.TrimStart('-')

$BaseDir    = "D:\LocalScripts"
$GroupDir   = Join-Path $BaseDir $Group
$ScriptPath = Join-Path $GroupDir "$ScriptName.ps1"

# --- Validation ---
if (-not (Test-Path $GroupDir)) {
    Write-Host "Group '$Group' not found. Expected folder: $GroupDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available groups:" -ForegroundColor Yellow
    Get-ChildItem $BaseDir -Directory | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}

if (-not (Test-Path $ScriptPath)) {
    Write-Host "Script '$ScriptName' not found in group '$Group'." -ForegroundColor Red
    Write-Host ""
    Write-Host "Available scripts in '$Group':" -ForegroundColor Yellow
    Get-ChildItem $GroupDir -Filter "*.ps1" | ForEach-Object {
        Write-Host "  $($_.BaseName)"
    }
    exit 1
}

# --- Execute ---
Write-Host "Running [$Group] $ScriptName" -ForegroundColor Cyan
Write-Host ""

& $ScriptPath @RemainingArgs
