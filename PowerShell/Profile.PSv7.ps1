
# Custom functions

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

function Update-Profile {
    Remove-Module Profile
    . "$PSScriptRoot/Profile.ps1" -Update
}

# cd root (of current git repo)
function cdr {
    Set-Location (git rev-parse --show-toplevel || Get-Location)
}

# fd find
function fdf {
    $global:fdf = fd --color=always @args | fzf --ansi --scheme=path --footer="$(Get-Location)" --preview="bat --color=always --style=plain {} 2> $($IsWindows ? 'NUL' : '/dev/null') || fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}" -m
    $global:fdf # Intentional shadowing
}

# cd find (in current git repo, if any)
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

# cdd: cdf in current directory
function cdd {
    cdf -BaseDir (Get-Location -PSProvider FileSystem).ProviderPath @args
}
