
function Update-Dotfiles {
    try {
        Write-Host -ForegroundColor Yellow "UPDATING: dotfiles"
        Push-Location -Path "$PSScriptRoot" && git pull -r && ./Install.ps1
    }
    finally {
        Pop-Location
    }
}

function cdr { # cd root
    Set-Location (git rev-parse --show-toplevel || Get-Location)
}

function cdf { # cd find
    Set-Location (fd --type=d --color=always ($args ? $args : '.') (git rev-parse --show-toplevel 2> $null || (Get-Location).Path).Replace('/', $IsWindows ? '\' : '/') | fzf --ansi --reverse --style=full --scheme=path || Get-Location)
}

function gs { # git status
    git status $args && Write-Host "" && git log -1 --pretty=short
}

function gpr { # git pull --rebase
    git pull --rebase $args
}
