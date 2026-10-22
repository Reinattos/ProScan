#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InstallPath = 'C:\ProScan\ProScan.ps1',
    [string]$ShortcutPath = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'ProScan.lnk')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $InstallPath)) {
    throw "O arquivo do ProScan não foi encontrado em: $InstallPath"
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallPath`""
$shortcut.WorkingDirectory = Split-Path -Parent $InstallPath
$shortcut.IconLocation = "$env:WINDIR\System32\shell32.dll, 22"
$shortcut.Description = 'Abrir o ProScan v2.1 - diagnóstico do Windows'
$shortcut.Save()
Write-Host "Atalho criado em: $ShortcutPath"
