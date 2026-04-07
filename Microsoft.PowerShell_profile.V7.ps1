
# Configuration

$PSStyle.FileInfo.Directory = "`e[1;96m" # Bold bright cyan
$PSStyle.FileInfo.SymbolicLink = "`e[95m" # Bright magenta
$PSStyle.FileInfo.Executable = "`e[91m" # Bright red

$PSStyle.FileInfo.Extension.Clear()
$PSStyle.FileInfo.Extension['.ps1'] = "`e[31m" # Red

foreach ($key in @('.csproj', '.props', '.targets', '.sln', '.slnx', '.toml')) {
    $PSStyle.FileInfo.Extension[$key] = "`e[93m" # Bright yellow
}

# Custom functions

function Update-Dotfiles {
    try {
        Write-Host -ForegroundColor Yellow "UPDATING: dotfiles"
        Push-Location -Path $PSScriptRoot -ErrorAction Stop
        git pull -r && ./Install.ps1
    }
    finally {
        Pop-Location
    }
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
    $currentDir = (Get-Location).Path
    $baseDir = (git rev-parse --show-toplevel 2> $null || $currentDir).Replace('/', $IsWindows ? '\' : '/')
    $footer = $baseDir -eq $currentDir ? $baseDir : "Search:  $baseDir`nCurrent: $currentDir"

    Set-Location $baseDir

    $selectedDir = (& { '.'; fd --type=d --color=always @args } @args
        | fzf --ansi --scheme=path --footer="$footer" --preview='fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}'
    )

    Set-Location ($selectedDir ? (Resolve-Path -Path $selectedDir -RelativeBasePath $baseDir) : $currentDir)
}
