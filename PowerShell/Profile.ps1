param ([switch]$Update)

Import-Module "$PSScriptRoot/Profile.All.psm1" -Global

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module "$PSScriptRoot/Profile.PSv7.psm1" -Global
}

if ($Update -or -not (Test-Path "$PSScriptRoot/Profile.Generated.psm1")) {
    . "$PSScriptRoot/Profile.Generator.ps1" > "$PSScriptRoot/Profile.Generated.psm1"
}

Import-Module "$PSScriptRoot/Profile.Generated.psm1" -Global
