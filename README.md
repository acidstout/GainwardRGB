# Set RGB lighting without EXPERTool running permanently

This script allows to set your configured RGB lighting during Windows startup without having the Gainward EXPERTool running in the background all the time. It creates a task in Task Scheduler to run an elevated user session hidden in the background to set your previously configured RGB lighting, and force quites the EXPERTool after five seconds automatically.

## Problem

Gainward EXPERTool does not persist RGB settings across reboots. The tool must be launched after every boot to re-apply the configured color. However, it has no command-line interface, no "minimize to tray" option, and no built-in auto-start — requiring manual launch and close on every boot.

## Solution

A PowerShell script launches the EXPERTool in a non-interactive background session via Task Scheduler, waits for the RGB to be applied, then terminates the process. The scheduled task runs under the current user account with elevated privileges and the `Password` logon type, which means it executes in a background session — no window, no taskbar flash, fully invisible.

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later (included in Windows 10+)
- Gainward EXPERTool installed with RGB color pre-configured
- Administrator privileges (for task registration)

## Files

| File | Purpose |
|---|---|
| `Install-GainwardRGB.ps1` | Installer — registers the scheduled task, patches placeholders, cleans up temp files |
| `Set-GainwardRGB.ps1` | Main script — launches EXPERTool, waits, kills it |
| `Set-GainwardRGB-Task.xml` | Task Scheduler XML template with `__USERNAME__` and `__SCRIPTPATH__` placeholders |
| `README.md` | This file |

## Installation

1. Install Gainward EXPERTool

1. Place all files in the Gainward EXPERTool directory (e.g. `C:\Program Files\Gainward\EXPERTool\`). The task will reference the script at this location, so do not move the files after installation.

2. Open Gainward EXPERTool manually and configure the desired RGB color. Close the tool. This only needs to be done once — the tool saves its settings per user profile.

3. Open an elevated PowerShell prompt, navigate to the directory, and run:

```powershell
.\Install-GainwardRGB.ps1
```

4. When prompted, enter your Windows password. This is required because the task runs with the `Password` logon type to enable background execution under your user account.

The installer will:
- Remove any previously registered `Set-GainwardRGB` task
- Patch the XML template with your username and the script's absolute path
- Import the scheduled task via `schtasks`
- Delete the temporary patched XML from `%TEMP%`

## Configuration

Edit `Set-GainwardRGB.ps1` to adjust these variables:

| Variable | Default | Description |
|---|---|---|
| `$ExePath` | `C:\Program Files\Gainward EXPERTool\TBPanel.exe` | Full path to the EXPERTool executable |
| `$WaitSeconds` | `5` | Seconds to wait before killing the process — increase if RGB does not apply reliably |

The XML template contains a logon trigger delay of `PT10S` (10 seconds after logon). This gives the GPU driver time to fully initialize. Adjust the `<Delay>` value in `Set-GainwardRGB-Task.xml` before running the installer if needed.

## Uninstallation

Run in an elevated PowerShell:

```powershell
Unregister-ScheduledTask -TaskName "Set-GainwardRGB" -Confirm:$false
```

Then delete the script files from their directory.

## Troubleshooting

**RGB does not apply**
Increase `$WaitSeconds` in the main script (try 8 or 10). If that doesn't help, verify that the EXPERTool applies the color when launched manually — the tool saves settings per user, and the task must run under the same account.

**Task shows status 0x41301 ("The task is currently running")**
This is normal while the script is sleeping. Refresh Task Scheduler after ~15 seconds — it should show 0x0 (success).

**Task shows error 0xFFD0000**
Usually a path issue. Verify that `$ExePath` in the main script points to the correct executable. Run the script manually to see the error:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "path\to\Set-GainwardRGB.ps1"
```

**"The principal name is invalid" on import**
Do not import the XML template directly — use `Install-GainwardRGB.ps1`, which patches the `__USERNAME__` placeholder before import.

**RGB stops working after moving the script files**
The scheduled task references the script's absolute path at install time. Re-run `Install-GainwardRGB.ps1` from the new location to update the task.

**Task needs to be updated after a password change**
Re-run `Install-GainwardRGB.ps1` and enter the new password when prompted.
