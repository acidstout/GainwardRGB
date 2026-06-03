#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs the Set-GainwardRGB scheduled task.
.DESCRIPTION
    - Patches the XML template with the current username and script path
    - Imports the task (prompts for password)
    - Cleans up temporary files
    The main script runs from wherever you place these files.
.NOTES
    Run this script elevated from the directory containing:
      - Set-GainwardRGB.ps1
      - Set-GainwardRGB-Task.xml
#>

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$TaskName    = "Set-GainwardRGB"
$ScriptFile  = "Set-GainwardRGB.ps1"
$XmlTemplate = "Set-GainwardRGB-Task.xml"
$PatchedXml  = Join-Path $env:TEMP "Set-GainwardRGB-Task-patched.xml"
$ScriptPath  = Join-Path $ScriptDir $ScriptFile

# --- Validate source files ---
foreach ($file in @($ScriptFile, $XmlTemplate)) {
    $path = Join-Path $ScriptDir $file
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error "Missing required file: $path"
        exit 1
    }
}

# --- Remove existing task if present ---
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task '$TaskName'" -ForegroundColor Yellow
}

# --- Patch XML with current username and script path, then import ---
$xmlContent = Get-Content (Join-Path $ScriptDir $XmlTemplate) -Raw
$xmlContent = $xmlContent -replace '__USERNAME__', $env:USERNAME
$xmlContent = $xmlContent -replace '__SCRIPTPATH__', $ScriptPath
$xmlContent | Set-Content -Path $PatchedXml -Encoding Unicode

Write-Host "`nImporting scheduled task as user '$env:USERNAME'..." -ForegroundColor Cyan
Write-Host "Script location: $ScriptPath" -ForegroundColor Cyan
schtasks /create /xml $PatchedXml /tn $TaskName /rp * /f

if ($LASTEXITCODE -ne 0) {
    Write-Error "Task import failed (exit code $LASTEXITCODE)"
    Remove-Item -LiteralPath $PatchedXml -Force -ErrorAction SilentlyContinue
    exit 1
}

# --- Cleanup ---
Remove-Item -LiteralPath $PatchedXml -Force
Write-Host "`nCleanup complete." -ForegroundColor Green
Write-Host "Task '$TaskName' installed successfully." -ForegroundColor Green