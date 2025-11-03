
function Update-Dotfiles {
    try {
        Write-Host -ForegroundColor Yellow "UPDATING: dotfiles"
        Push-Location -Path "$PSScriptRoot" && git pull -r && ./Install.ps1
    }
    finally {
        Pop-Location
    }
}
