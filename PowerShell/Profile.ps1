
Import-Module "$PSScriptRoot/Profile.All.psm1" -Global

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module "$PSScriptRoot/Profile.PSv7.psm1" -Global
}
