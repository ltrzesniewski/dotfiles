
Write-Output ""
Write-Output "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if (Get-Command "git" -ErrorAction Ignore) {
    $commitHash = git -C $PSScriptRoot rev-parse HEAD
    Write-Output "# Commit: $commitHash"
}

# Colors

if (Get-Command vivid -ErrorAction Ignore) {
    $theme = 'catppuccin-mocha'

    Write-Output ""
    Write-Output "# Vivid: $(vivid --version)"
    Write-Output "# Theme: $theme"

    $colors = vivid generate $theme
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

    $colors = $context.colors

    Write-Output @"

`$env:LS_COLORS = '$colors'

`$ext = `$PSStyle.FileInfo.Extension;

if (`$null -ne `$ext) {
    `$PSStyle.FileInfo.Directory = "``e[$($colorsByPattern['di'])m"
    `$PSStyle.FileInfo.SymbolicLink = "``e[$($colorsByPattern['ln'])m"
    `$PSStyle.FileInfo.Executable = "``e[$($colorsByPattern['ex'])m"

    `$ext.Clear()
"@

    foreach ($key in $colorsByPattern.Keys) {
        if ($key -match '^\*(\.\w+)$') {
            $key = $Matches[1]
            $value = $colorsByPattern["*$key"]
            Write-Output "    `$ext['$key'] = `"``e[${value}m`""
        }
    }

    Write-Output "}"
}
else {
    Write-Warning "MISSING: vivid"
}
