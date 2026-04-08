
# Shell tools

if (Get-Command oh-my-posh -ErrorAction Ignore) {
    oh-my-posh init pwsh --config "$PSScriptRoot/prompt.omp.json" | Invoke-Expression
}

if (Get-Command atuin -ErrorAction Ignore) {
    $prevSession = $env:ATUIN_SESSION
    atuin init powershell | Out-String | Invoke-Expression
    if ($prevSession) {
        $env:ATUIN_SESSION = $prevSession
    }
}

# Argument completion

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

$env:ATUIN_CONFIG_DIR = "$PSScriptRoot/atuin"
$env:BAT_CONFIG_DIR = "$PSScriptRoot/bat"
$env:RIPGREP_CONFIG_PATH = "$PSScriptRoot/.ripgreprc"

$env:FZF_DEFAULT_OPTS = @'
    --style full:rounded
    --reverse
    --color dark,hl:bright-red:underline,hl+:bright-red:underline
'@

# Custom functions

function Remove-BinObj {
    Get-ChildItem -Include @('bin', 'obj') -Directory -Recurse | Remove-Item -Recurse
}

# dotnet build summary
function dbs {
    dotnet build @args | & "$PSScriptRoot/tools/dotnet/build-summary.ps1"
}

# fd hyperlink
function fdh {
    fd --hyperlink=auto @args
}

# rg raw
function rgr {
    rg --no-heading --no-filename --no-line-number @args
}

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

# Version-specific profile
if ($PSVersionTable.PSVersion.Major -ge 7) {
    . $PSScriptRoot/Microsoft.PowerShell_profile.V7.ps1
}
