
if (Get-Command oh-my-posh -ErrorAction Ignore) {
    oh-my-posh init pwsh --config "$PSScriptRoot/prompt.omp.json" | Invoke-Expression
}

if ((Get-Command atuin -ErrorAction Ignore) -and (Get-Module PSReadLine -ErrorAction Ignore)) {
    $env:ATUIN_CONFIG_DIR = "$PSScriptRoot/atuin"
    atuin init powershell | Out-String | Invoke-Expression
}

if (Get-Command dotnet -ErrorAction Ignore) {
    if ([int]($(dotnet --version) -replace '^(\d+)\..+', '$1') -ge 10) {
        dotnet completions script pwsh | Out-String | Invoke-Expression -ErrorAction Ignore
    }
    else {
        Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)
            dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        }
    }
}

if (Get-Command kubectl -ErrorAction Ignore) {
    kubectl completion powershell | Out-String | Invoke-Expression
}

if (Get-Command rg -ErrorAction Ignore) {
    $env:RIPGREP_CONFIG_PATH = "$PSScriptRoot/.ripgreprc"
    rg --generate complete-powershell | Out-String | Invoke-Expression
}

Import-Module -Name Terminal-Icons -ErrorAction Ignore

# Configuration

$env:BAT_CONFIG_DIR = "$PSScriptRoot/bat"

$env:FZF_DEFAULT_OPTS = @'
    --style full
    --reverse
    --color dark,hl:bright-red:underline,hl+:bright-red:underline
'@

# Custom functions

function Remove-BinObj {
    Get-ChildItem -Include @('bin', 'obj') -Directory -Recurse | Remove-Item -Recurse
}

# dotnet build summary
function dbs {
    dotnet build $args | & "$PSScriptRoot/tools/dotnet/build-summary.ps1"
}

# fd find
function fdf {
    $global:fdf = fd --color=always $args | fzf --ansi --scheme=path --preview='bat --color=always -n {}' -m
    $global:fdf
}

# fd hyperlink
function fdh {
    fd --hyperlink=auto $args
}

# rg raw
function rgr {
    rg --no-heading --no-filename --no-line-number $args
}

# rg delta
function rgd {
    rg --json $args | delta
}

# Aliases

Set-Alias ll Get-ChildItem

# Key bindings

Set-PSReadLineKeyHandler -Chord "Ctrl+UpArrow" -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord "Ctrl+DownArrow" -Function NextHistory

# Version-specific profile
if ($PSVersionTable.PSVersion.Major -ge 7) {
    . $PSScriptRoot/Microsoft.PowerShell_profile.V7.ps1
}
