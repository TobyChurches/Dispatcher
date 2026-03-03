# Dispatcher
### PowerShell Script Dispatcher — User Guide & Reference

---

## Overview

Dispatcher is a lightweight command-line dispatcher that lets you invoke named PowerShell scripts organised by group, from any terminal on your machine — PowerShell, CMD, or Windows Terminal.

Instead of navigating to a folder and running a script manually, you simply type:

```powershell
Dispatcher <group> -<scriptname> [optional parameters]

# Examples
Dispatcher azure -restart-app
Dispatcher dev   -clean-build  -Solution C:\Projects\MyApp.sln
Dispatcher iis   -recycle-pool -PoolName DefaultAppPool
```

---

## Directory Structure

All scripts live under `D:\LocalScripts`, organised into subfolders (groups):

```
D:\LocalScripts\
├── Dispatcher.ps1          ← Dispatcher (the engine)
├── azure\
│   ├── restart-app.ps1
│   └── clear-cache.ps1
├── dev\
│   ├── clean-build.ps1
│   └── run-migrations.ps1
└── iis\
    └── recycle-pool.ps1
```

> ✔ Adding a new group is as simple as creating a new subfolder. No configuration changes needed.

---

## Installation

### Step 1 — Create the Base Folder

Open an elevated PowerShell and run:

```powershell
New-Item -ItemType Directory -Path 'D:\LocalScripts' -Force
```

### Step 2 — Save the Dispatcher Script

Save the following as `D:\LocalScripts\Dispatcher.ps1`:

```powershell
<#
.SYNOPSIS
    Dispatcher.
    Usage: Dispatcher <group> -<scriptname> [args]
#>
param(
    [Parameter(Position = 0, Mandatory = $true)]  [string]$Group,
    [Parameter(Position = 1, Mandatory = $true)]  [string]$ScriptName,
    [Parameter(ValueFromRemainingArguments = $true)] $RemainingArgs
)

$ScriptName = $ScriptName.TrimStart('-')
$BaseDir    = 'D:\LocalScripts'
$GroupDir   = Join-Path $BaseDir $Group
$ScriptPath = Join-Path $GroupDir "$ScriptName.ps1"

if (-not (Test-Path $GroupDir)) {
    Write-Host "❌ Group '$Group' not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Available groups:" -ForegroundColor Yellow
    Get-ChildItem $BaseDir -Directory | ForEach-Object {
        Write-Host "  • $($_.Name)"
    }
    exit 1
}

if (-not (Test-Path $ScriptPath)) {
    Write-Host "❌ Script '$ScriptName' not found in '$Group'." -ForegroundColor Red
    Write-Host ""
    Write-Host "Available scripts in '$Group':" -ForegroundColor Yellow
    Get-ChildItem $GroupDir -Filter '*.ps1' | ForEach-Object {
        Write-Host "  • -$($_.BaseName)"
    }
    exit 1
}

Write-Host "Running [$Group] $ScriptName" -ForegroundColor Cyan
Write-Host ""
& $ScriptPath @RemainingArgs
```

### Step 3 — Install the Global Shim

This creates a CMD shim in System32 so `Dispatcher` works from any prompt. Run **once** in an elevated PowerShell:

```powershell
$shim = '@echo off' + [Environment]::NewLine +
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\LocalScripts\Dispatcher.ps1" %*'

Set-Content -Path 'C:\Windows\System32\Dispatcher.cmd' `
            -Value $shim -Encoding ASCII

Write-Host '✅ Dispatcher installed.' -ForegroundColor Green
```

> ⚠ This step requires an elevated (Run as Administrator) PowerShell session.

### Step 4 — Set Execution Policy

If not already configured on your machine, run once in elevated PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Usage

### Basic Syntax

```powershell
Dispatcher <group> -<scriptname>
Dispatcher <group> -<scriptname> -Param1 value1 -Param2 value2
```

### Examples

| Command | What it does |
|---|---|
| `Dispatcher azure -restart-app` | Restarts the default Azure App Service |
| `Dispatcher azure -restart-app -AppName myapi` | Restarts a named App Service |
| `Dispatcher dev -clean-build` | Cleans and rebuilds the default solution |
| `Dispatcher iis -recycle-pool -PoolName mypool` | Recycles a named IIS App Pool |

### Error Handling

The dispatcher provides helpful errors automatically:

```powershell
# Wrong group name
Dispatcher wronggroup -myscript
> ❌ Group 'wronggroup' not found.
> Available groups: azure, dev, iis

# Wrong script name
Dispatcher azure -nonexistent
> ❌ Script 'nonexistent' not found in 'azure'.
> Available scripts: -restart-app, -clear-cache
```

---

## Writing Your Own Scripts

Each script is a standard `.ps1` file inside its group folder. Parameters are forwarded automatically from the command line.

### Template

```powershell
# D:\LocalScripts\<group>\<scriptname>.ps1

param(
    [string]$Param1 = 'default-value',
    [string]$Param2 = 'another-default'
)

Write-Host "Running with Param1=$Param1" -ForegroundColor Cyan

# Your logic here
```

### Azure Example

```powershell
# D:\LocalScripts\azure\restart-app.ps1
param(
    [string]$AppName       = 'my-default-app',
    [string]$ResourceGroup = 'my-rg'
)

Write-Host "🔄 Restarting $AppName..." -ForegroundColor Yellow
az webapp restart --name $AppName --resource-group $ResourceGroup
Write-Host "✅ Done." -ForegroundColor Green
```

### .NET / Dev Example

```powershell
# D:\LocalScripts\dev\clean-build.ps1
param(
    [string]$Solution = '.'
)

Write-Host "🧹 Cleaning solution..." -ForegroundColor Yellow
dotnet clean $Solution
dotnet build $Solution
Write-Host "✅ Build complete." -ForegroundColor Green
```

---

## Optional: Tab Completion

Add the following to your PowerShell profile to enable tab-completion on group names:

```powershell
# Add to $PROFILE (PowerShell 7+)
Register-ArgumentCompleter -CommandName 'Dispatcher' `
  -ParameterName 'Group' -ScriptBlock {
    param($cmd, $param, $word)
    Get-ChildItem 'D:\LocalScripts' -Directory |
      Where-Object { $_.Name -like "$word*" } |
      ForEach-Object { $_.Name }
}
```

Find your profile path by running `$PROFILE` in PowerShell.

---

## Quick Reference

| Item | Value / Location | Notes |
|---|---|---|
| Base directory | `D:\LocalScripts\` | All groups live here |
| Dispatcher | `D:\LocalScripts\Dispatcher.ps1` | The engine — do not rename |
| Global shim | `C:\Windows\System32\Dispatcher.cmd` | Makes command available everywhere |
| Add a group | Create a subfolder in `D:\LocalScripts\` | No config changes needed |
| Add a script | Add a `.ps1` to the group folder | Immediately available |
| Execution policy | `RemoteSigned (LocalMachine)` | Set once, elevated PS required |

> ✔ No restart or refresh required — new scripts and groups are available immediately after the file is saved.
