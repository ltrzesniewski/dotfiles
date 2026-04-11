
# Colors

& {
    $PSStyle.FileInfo.Directory = "`e[0;1;96m" # Bold bright cyan
    $PSStyle.FileInfo.SymbolicLink = "`e[0;95m" # Bright magenta
    $PSStyle.FileInfo.Executable = "`e[0;91m" # Bright red

    if (Get-Command vivid -ErrorAction Ignore) {
        $colors = vivid generate 'catppuccin-mocha'

        $colors = $colors -replace '\bdi=0;', 'di=0;1;' # Make directories bold
        $colorsByPattern = @{}

        foreach ($item in $colors -split ':') {
            $item = $item -split '=', 2
            $colorsByPattern[$item[0]] = $item[1]
        }

        $context = @{ colors = $colors }

        function Add-Color {
            param ([string]$ColorCode, [switch]$Bold, [string[]] $To)

            $value = if ($ColorCode -match '^#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$' ) {
                $r = [int]::Parse($Matches[1], 'HexNumber')
                $g = [int]::Parse($Matches[2], 'HexNumber')
                $b = [int]::Parse($Matches[3], 'HexNumber')
                "38;2;${r};${g};${b}"
            }
            else {
                $ColorCode
            }

            if ($Bold) { $value = "1;${value}" }
            if (-not $value.StartsWith('0;')) { $value = "0;${value}" }

            foreach ($ext in $To) {
                $colorsByPattern["*.$ext"] = $value
                $context.colors += ":*.${ext}=${value}"
            }
        }

        function Add-ColorAlias {
            param ([string]$From, [string[]] $To)
            Add-Color -ColorCode $colorsByPattern["*.$From"] -To $To
        }

        Add-Color '#ffc944' -Bold 'csproj', 'props', 'targets', 'sln', 'slnx', 'toml'
        Add-ColorAlias 'zip' 'nuget'
        Add-ColorAlias 'sh' 'ps1'
        Add-ColorAlias 'cs' 'cshtml', 'razor', 'xaml'
        Add-ColorAlias 'lock' 'DotSettings', 'user', 'binlog', 'vsconfig'

        $PSStyle.FileInfo.Extension.Clear()
        foreach ($key in $colorsByPattern.Keys) {
            if ($key -match '^\*(\..+)$') {
                $PSStyle.FileInfo.Extension[$Matches[1]] = "`e[$($colorsByPattern[$key])m"
            }
        }

        $env:LS_COLORS = $context.colors

        $PSStyle.FileInfo.Directory = "`e[$($colorsByPattern['di'])m"
        $PSStyle.FileInfo.SymbolicLink = "`e[$($colorsByPattern['ln'])m"
        $PSStyle.FileInfo.Executable = "`e[$($colorsByPattern['ex'])m"
    }
}

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
