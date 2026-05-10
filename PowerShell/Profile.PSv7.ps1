
# Custom functions

# .SYNOPSIS
# Updates the dotfiles repo from git
function Update-Dotfiles {
    try {
        Write-Host -ForegroundColor Yellow "UPDATING: dotfiles"
        Push-Location -Path "$PSScriptRoot/.." -ErrorAction Stop
        git pull -r && ./Install.ps1
    }
    finally {
        Pop-Location
    }
}

# .SYNOPSIS
# Reloads the Profile module
function Update-Profile {
    Remove-Module Profile
    . "$PSScriptRoot/Profile.ps1" -Update
}

# .SYNOPSIS
# cd root - of current git repo
function cdr {
    Set-Location (git rev-parse --show-toplevel || Get-Location)
}

# .SYNOPSIS
# fd find
function fdf {
    $global:fdf = fd --color=always @args | fzf --ansi --scheme=path --footer="$(Get-Location)" --preview="bat --color=always --style=plain {} 2> $($IsWindows ? 'NUL' : '/dev/null') || fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}" -m
    $global:fdf # Intentional shadowing
}

# .SYNOPSIS
# cd find - in current git repo
function cdf {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [string]$BaseDir,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$FdArgs
    )

    $currentDir = (Get-Location -PSProvider FileSystem).ProviderPath
    $BaseDir = $BaseDir -eq '' ? (git rev-parse --show-toplevel 2> $null || $currentDir).Replace('/', $IsWindows ? '\' : '/') : $BaseDir
    $footer = $BaseDir -eq $currentDir ? $BaseDir : "Scope:   $BaseDir`nCurrent: $currentDir"

    Set-Location $BaseDir

    $selectedDir = (& { '.'; fd --type=d --color=always @FdArgs } @FdArgs
        | fzf --ansi --scheme=path --footer="$footer" --preview='fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}'
    )

    Set-Location ($selectedDir ? (Resolve-Path -Path $selectedDir -RelativeBasePath $BaseDir) : $currentDir)
}

# .SYNOPSIS
# cd find - in current directory
function cdd {
    cdf -BaseDir (Get-Location -PSProvider FileSystem).ProviderPath @args
}
