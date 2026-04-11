param ([switch]$Update)

if ($Update -or -not (Test-Path "$PSScriptRoot/Profile.Generated.ps1")) {
    Write-Host -ForegroundColor Yellow "UPDATING: Profile.Generated.ps1"
    . "$PSScriptRoot/Profile.Generator.ps1" > "$PSScriptRoot/Profile.Generated.ps1"
}

Import-Module "$PSScriptRoot/Profile.psm1" -Global
