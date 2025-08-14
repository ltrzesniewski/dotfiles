
Function Install-App {
    param (
        [string]$AppName,
        [scriptblock]$ScriptBlock,
        [int[]]$ValidExitCodes = @()
    )

    Write-Host ""
    Write-Host -ForegroundColor Yellow "INSTALLING: $AppName"
    & @ScriptBlock
    if ($LastExitCode -ne 0 -and $ValidExitCodes -notcontains $LastExitCode) {
        Write-Host -ForegroundColor Red "    FAILED: $AppName"
        exit $LastExitCode
    }
}

Function Install-WinGet {
    param (
        [string]$AppName,
        [string]$PackageName
    )

    Install-App $AppName { winget install --source winget --silent $PackageName } -ValidExitCodes @(0x8A15002B)
}

# Add profile script

if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

if (!(Select-String -Path $PROFILE -Pattern "~/dotfiles/Microsoft.PowerShell_profile.ps1" -Quiet)) {
    Add-Content -Path $PROFILE -Value ". ~/dotfiles/Microsoft.PowerShell_profile.ps1"
}

# Install WinGet apps

Install-WinGet "PowerShell" "Microsoft.Powershell"
Install-WinGet "OhMyPosh" "JanDeDobbeleer.OhMyPosh"
Install-WinGet "fzf" "fzf"
Install-WinGet "jq" "jqlang.jq"

# Install dotnet tools

if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    Install-App "C# REPL" { dotnet tool update -g csharprepl }
}

# Install Rust apps

if (Get-Command "rustup" -ErrorAction SilentlyContinue) {
    Install-App "rust update" { rustup update stable }
}

if (Get-Command "cargo" -ErrorAction SilentlyContinue) {
    Install-App "atuin" { cargo install --git https://github.com/ltrzesniewski/atuin.git --branch powershell-pr }
    Install-App "bat" { cargo install bat }
    Install-App "btm" { cargo install bottom }
    Install-App "fd" { cargo install fd-find }
    Install-App "ripgrep" { cargo install ripgrep --features pcre2 }
}

Write-Host ""
Write-Host -ForegroundColor Yellow "DONE"
Write-Host ""
