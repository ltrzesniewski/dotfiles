
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$settingsFile = "$env:LocalAppData\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
$overridesFile = "$PSScriptRoot\WindowsTerminal.json"

if (!(Test-Path -Path $settingsFile)) {
    throw "Settings file not found: $settingsFile"
}

$newConfig = jq -s '.[0] * .[1]' $settingsFile $overridesFile
if (-not $?) {
    throw "Could not merge settings"
}

Out-File -InputObject $newConfig -FilePath $settingsFile
Write-Host "Windows Terminal settings updated"
