
if ($env:WT_SESSION) {
    if (Get-Command oh-my-posh -ErrorAction Ignore) {
        oh-my-posh init pwsh --config "$PSScriptRoot/prompt.omp.json" | Invoke-Expression
    }

    Import-Module -Name Terminal-Icons -ErrorAction Ignore
}

if (Get-Command kubectl -ErrorAction Ignore) {
    kubectl completion powershell | Out-String | Invoke-Expression
}

if (Get-Command rg -ErrorAction Ignore) {
    $env:RIPGREP_CONFIG_PATH = "$PSScriptRoot/.ripgreprc"
    rg --generate complete-powershell | Out-String | Invoke-Expression
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Atuin
if (Get-Command atuin -ErrorAction Ignore) {
    $env:ATUIN_SESSION = (atuin uuid | Out-String).Trim()
    $env:ATUIN_HISTORY_ID = $null

    Set-PSReadLineKeyHandler -Chord Enter -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if (-not $env:ATUIN_HISTORY_ID) {
            $env:ATUIN_HISTORY_ID = (atuin history start -- $line | Out-String).Trim()
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    $existingPromptFunction = Get-Item -Path Function:\prompt
    Remove-Item -Path Function:\prompt
    function prompt {
        if ($env:ATUIN_HISTORY_ID) {
            atuin history end --duration (Get-History -Count 1).Duration.TotalNanoseconds --exit $LASTEXITCODE -- $env:ATUIN_HISTORY_ID | Out-Null

            Remove-Item -Path env:ATUIN_HISTORY_ID -ErrorAction SilentlyContinue
        }

        & $existingPromptFunction.ScriptBlock
    }

    # $InvokeAtuinSearch = {
    #     $keymapMode = "emacs"

    #     $line = $null
    #     $cursor = $null
    #     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    #     $suggestion = (atuin search --keymap-mode=$keymapMode -i -- $line | Out-String).Trim()

    #     [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

    #     if ($suggestion.StartsWith("__atuin_accept__:")) {
    #         $suggestion = $suggestion.Substring(16)
    #         [Microsoft.PowerShell.PSConsoleReadLine]::Insert($suggestion)
    #         [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    #     }
    #     else {
    #         [Microsoft.PowerShell.PSConsoleReadLine]::Insert($suggestion)
    #     }
    # }

    # Set-PSReadLineKeyHandler -Chord "Ctrl+r" -ScriptBlock $InvokeAtuinSearch -BriefDescription "AtuinSearch" -Description "Invoke Atuin search for command history"
}
