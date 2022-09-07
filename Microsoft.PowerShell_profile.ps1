
if ($env:WT_SESSION)
{
    if (Get-Command oh-my-posh -ErrorAction Ignore)
    {
        oh-my-posh init pwsh --config "$PSScriptRoot/prompt.omp.json" | Invoke-Expression
    }

    Import-Module -Name Terminal-Icons -ErrorAction Ignore
}

if (Get-Command kubectl -ErrorAction Ignore)
{
    kubectl completion powershell | Out-String | Invoke-Expression
}

. "$PSScriptRoot/PowerShell/_rg.ps1"
