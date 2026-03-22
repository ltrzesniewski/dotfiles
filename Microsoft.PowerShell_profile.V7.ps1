
function Update-Dotfiles {
    try {
        Write-Host -ForegroundColor Yellow "UPDATING: dotfiles"
        Push-Location -Path "$PSScriptRoot" && git pull -r && ./Install.ps1
    }
    finally {
        Pop-Location
    }
}

# cd root (of current git repo)
function cdr {
    Set-Location (git rev-parse --show-toplevel || Get-Location)
}

# cd find (in current git repo, if any)
function cdf {
    $currentDir = (Get-Location).Path
    $baseDir = git rev-parse --show-toplevel 2> $null || $currentDir

    try {
        Set-Location $baseDir

        $selectedDir = (fd --type=d --color=always ($args ? $args : '.')
            | fzf --ansi --scheme=path --preview='fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}'
        )

        Set-Location ($selectedDir ? (Join-Path $baseDir $selectedDir) : $currentDir)
    }
    catch {
        Set-Location $currentDir
        throw
    }
}

# git status
function gs {
    git status $args && Write-Host "" && git log -1 --pretty=short
}

# git pull --rebase
function gpr {
    git pull --rebase $args
}
