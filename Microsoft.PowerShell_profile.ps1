
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
