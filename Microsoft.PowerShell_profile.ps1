
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

# Custom functions

function Remove-BinObj {
    Get-ChildItem -Include @('bin', 'obj') -Directory -Recurse | Remove-Item -Recurse
}

function fdf {
    fd --type=f --strip-cwd-prefix --color=always $args | fzf --ansi --reverse --style=full --preview='bat --color=always -n {}' --scheme=path --color='dark,hl:bright-red:underline,hl+:bright-red:underline' -m
}

function fdh {
    fd --hyperlink=auto $args
}

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
