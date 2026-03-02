
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

function cdf {
    Set-Location (fd --type=d --color=always ($args ? $args : '.') (git rev-parse --show-toplevel 2> $null || (Get-Location).Path).Replace('/', '\') | fzf --ansi --reverse --style=full --scheme=path || Get-Location)
}
