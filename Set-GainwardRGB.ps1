#Requires -Version 5.1
<#
.SYNOPSIS
    Launches Gainward EXPERTool silently to apply RGB settings, then kills it.
.DESCRIPTION
    Starts the tool with a hidden window, waits for the RGB to be applied,
    then terminates the process. Designed to run via Task Scheduler at logon.
.NOTES
    Adjust $ExePath if your installation directory differs.
    Adjust $WaitSeconds if 5s is not enough for the RGB to apply.
#>

# --- Configuration ---
$ExePath      = "C:\Program Files\Gainward EXPERTool\TBPanel.exe"
$WaitSeconds  = 10

# --- Main ---
if (-not (Test-Path -LiteralPath $ExePath)) {
    Write-Error "Gainward EXPERTool not found at: $ExePath"
    exit 1
}

$processName = [System.IO.Path]::GetFileNameWithoutExtension($ExePath)

# Kill any lingering instance first
Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force

# Launch minimized (UI initializes but window stays in taskbar)
$proc = Start-Process -FilePath $ExePath -WindowStyle Minimized -PassThru

Start-Sleep -Seconds $WaitSeconds

# Terminate by process ID (no window title needed)
if (-not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
}
exit 0
