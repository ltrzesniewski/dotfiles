
. "$PSScriptRoot/Profile.All.ps1"

if ($PSVersionTable.PSVersion.Major -ge 7) {
    . "$PSScriptRoot/Profile.PSv7.ps1"
}

. "$PSScriptRoot/Profile.Generated.ps1"
