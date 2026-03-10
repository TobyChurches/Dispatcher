# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A single-file PowerShell script dispatcher (`Dispatcher.ps1`) that routes calls to named scripts organized in group subfolders under `D:\LocalScripts`.

**Invocation syntax:**
```powershell
Dispatcher <group> <scriptname> [params]
# or with legacy dash prefix:
Dispatcher <group> -<scriptname> [params]
```

## How It Works

- `Dispatcher.ps1` is the engine — it resolves `D:\LocalScripts\<group>\<scriptname>.ps1` and delegates execution via `& $ScriptPath @RemainingArgs`
- Groups are just subfolders; no registration or config needed
- Tab completion is built into the script via `[ArgumentCompleter]` attributes on both `$Group` and `$ScriptName` parameters
- A CMD shim at `C:\Windows\System32\Dispatcher.cmd` makes the command available from any terminal

## Adding Scripts

Drop a `.ps1` file into a group subfolder — it's immediately available. Use standard `param()` blocks; all extra args are forwarded automatically.

## Key Constraints

- Base directory is hardcoded to `D:\LocalScripts` in `Dispatcher.ps1`
- Renaming `Dispatcher.ps1` breaks the CMD shim
- The shim and execution policy setup require an elevated PowerShell session (one-time setup)
