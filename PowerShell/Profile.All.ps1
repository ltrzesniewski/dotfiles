
# Shell tools

if (Get-Command oh-my-posh -ErrorAction Ignore) {
    oh-my-posh init pwsh --config "$PSScriptRoot/../prompt.omp.json" | Invoke-Expression
}

if (Get-Command atuin -ErrorAction Ignore) {
    $prevSession = $env:ATUIN_SESSION
    atuin init powershell | Out-String | Invoke-Expression
    if ($prevSession) {
        $env:ATUIN_SESSION = $prevSession
    }
}

# Argument completion

# .ROLE
# Internal
function Register-LazyCompleter {
    param ([string]$CommandName, [scriptblock]$ScriptBlock)

    # This requires pressing Ctrl+Space twice the first time, but it avoids loading the completion script until it's actually needed.
    Register-ArgumentCompleter -Native -CommandName $CommandName -ScriptBlock {
        & $ScriptBlock | Out-String | Invoke-Expression
        $null
    }.GetNewClosure()
}

Register-LazyCompleter 'atuin' { atuin gen-completions --shell powershell }
Register-LazyCompleter 'bat' { bat --completion ps1 }
Register-LazyCompleter 'delta' { delta --generate-completion powershell }
Register-LazyCompleter 'dotnet' { dotnet completions script pwsh }
Register-LazyCompleter 'fd' { fd --gen-completions powershell }
Register-LazyCompleter 'git' { Import-Module git-completion }
Register-LazyCompleter 'kubectl' { kubectl completion powershell }
Register-LazyCompleter 'rg' { rg --generate complete-powershell }
Register-LazyCompleter 'rustup' { rustup completions powershell }

# Configuration

$env:ATUIN_CONFIG_DIR = "$PSScriptRoot/../atuin"
$env:BAT_CONFIG_DIR = "$PSScriptRoot/../bat"
$env:RIPGREP_CONFIG_PATH = "$PSScriptRoot/../.ripgreprc"

$env:FZF_DEFAULT_OPTS = @'
    --style full:rounded
    --reverse
    --color dark,hl:bright-red:underline,hl+:bright-red:underline
'@

# Custom functions

# .SYNOPSIS
# Shows functions in the Profile module
function Get-ProfileHelp {
    function Out-Help {
        param([scriptblock]$Filter, [scriptblock]$Format = { $_.Synopsis })
        (Get-Module Profile).ExportedFunctions.Values |
        ForEach-Object { Get-Help $_ } |
        Where-Object { $_.Role -notmatch '^Internal\b' } |
        Where-Object $Filter |
        ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Description = & $Format $_ } } |
        Format-Table -Property Name, Description
    }

    $esc = [char]27 # Because of PS v5
    Out-Help { !$_.Name.Contains('-') } { $_.Synopsis -replace '^(\w+)', "${esc}[0;93m`$1${esc}[0m" }
    Out-Help { $_.Name.Contains('-') }
}

# .SYNOPSIS
# Removes .NET build outputs (bin/obj)
function Remove-BinObj {
    Get-ChildItem -Include @('bin', 'obj') -Directory -Recurse | Remove-Item -Recurse
}

# .SYNOPSIS
# dotnet build summary
function dbs {
    dotnet build @args | & "$PSScriptRoot/../tools/dotnet/build-summary.ps1"
}

# .SYNOPSIS
# dotnet test summary
function dts {
    dotnet test @args | & "$PSScriptRoot/../tools/dotnet/build-summary.ps1"
}

# .SYNOPSIS
# fd hyperlink
function fdh {
    fd --hyperlink=auto @args
}

# .SYNOPSIS
# rg raw
function rgr {
    rg --no-heading --no-filename --no-line-number @args
}

# .SYNOPSIS
# rg delta
function rgd {
    rg --json @args | delta
}

# Aliases

Set-Alias ll Get-ChildItem

# PSReadline

Set-PSReadlineOption -BellStyle None
Set-PSReadLineKeyHandler -Chord "Ctrl+UpArrow" -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord "Ctrl+DownArrow" -Function NextHistory
