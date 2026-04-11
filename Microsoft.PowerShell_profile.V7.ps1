
# Colors

& {
    $PSStyle.FileInfo.Directory = "`e[0;1;96m" # Bold bright cyan
    $PSStyle.FileInfo.SymbolicLink = "`e[0;95m" # Bright magenta
    $PSStyle.FileInfo.Executable = "`e[0;91m" # Bright red

    $PSStyle.FileInfo.Extension.Clear()
    $PSStyle.FileInfo.Extension['.ps1'] = "`e[0;31m" # Red

    foreach ($key in @('.csproj', '.props', '.targets', '.sln', '.slnx', '.toml')) {
        $PSStyle.FileInfo.Extension[$key] = "`e[0;1;93m" # Bold bright yellow
    }

    if (Get-Command vivid -ErrorAction Ignore) {
        $colors = vivid generate 'catppuccin-mocha'

        foreach ($key in $PSStyle.FileInfo.Extension.Keys) {
            $colors += ":*$key=" + ($PSStyle.FileInfo.Extension[$key] -replace "^`e\[|m$", '')
        }

        $colors = $colors -replace '\bdi=0;', 'di=0;1;' # Make directories bold
        $colorsByPattern = @{}

        foreach ($item in $colors -split ':') {
            $item = $item -split '=', 2
            $colorsByPattern[$item[0]] = $item[1]
        }

        function Add-ColorAlias {
            param ([string]$From, [string[]] $To)
            $value = $colorsByPattern["*.$From"]
            foreach ($ext in $To) {
                $colorsByPattern["*.$ext"] = $value
                $colors += "${colors}:*.${ext}=${value}"
            }
            $colors
        }

        $colors = Add-ColorAlias 'zip' 'nuget'
        $colors = Add-ColorAlias 'sh' 'ps1'
        $colors = Add-ColorAlias 'cs' 'cshtml', 'razor', 'xaml'
        $colors = Add-ColorAlias 'lock' 'DotSettings', 'user', 'binlog', 'vsconfig'

        foreach ($key in $colorsByPattern.Keys) {
            if ($key -match '^\*(\..+)$') {
                $PSStyle.FileInfo.Extension[$Matches[1]] = "`e[$($colorsByPattern[$key])m"
            }
        }

        $env:LS_COLORS = $colors

        $PSStyle.FileInfo.Directory = "`e[$($colorsByPattern['di'])m"
        $PSStyle.FileInfo.SymbolicLink = "`e[$($colorsByPattern['ln'])m"
        $PSStyle.FileInfo.Executable = "`e[$($colorsByPattern['ex'])m"
    }
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
