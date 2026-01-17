
function Update-Dotfiles {
    try {
        Write-Host -ForegroundColor Yellow "UPDATING: dotfiles"
        Push-Location -Path "$PSScriptRoot" && git pull -r && ./Install.ps1
    }
    finally {
        Pop-Location
    }
}

function cdr {
    Set-Location (git rev-parse --show-toplevel || Get-Location)
}
