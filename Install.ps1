
Function Write-Header {
    param ([string]$Text)

    Write-Host ""
    Write-Host -ForegroundColor Yellow $Text
}

Function Install-App {
    param (
        [string]$AppName,
        [scriptblock]$ScriptBlock,
        [int[]]$ValidExitCodes = @()
    )

    Write-Header "INSTALLING: $AppName"
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

    Install-App $AppName { winget install --source winget --silent --exact $PackageName } -ValidExitCodes @(0x8A15002B)
}

# Add profile script and other one-time stuff

& {
    if (!(Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $origContent = Get-Content -LiteralPath $PROFILE -Raw -Encoding UTF8
    $content = $origContent.Replace('. ~/dotfiles/Microsoft.PowerShell_profile.ps1', '. ~/dotfiles/PowerShell/Profile.ps1')
    if (-not $content.Contains('. ~/dotfiles/PowerShell/Profile.ps1')) {
        $content = @"
. ~/dotfiles/PowerShell/Profile.ps1

$content
"@
    }

    if ($content -ne $origContent) {
        Write-Host ""
        Write-Host -ForegroundColor Yellow "UPDATING: PowerShell profile"
        Set-Content -LiteralPath $PROFILE -Value $content -Encoding UTF8
    }

    if (Get-Command "git" -ErrorAction SilentlyContinue) {
        $gitcfg = git config list --global
        if ($gitcfg -notcontains 'include.path=~/dotfiles/.gitconfig') {
            git config set --global --append include.path '~/dotfiles/.gitconfig'
        }
        if ($IsWindows -and $gitcfg -notcontains 'include.path=~/dotfiles/.gitconfig-windows') {
            git config set --global --append include.path '~/dotfiles/.gitconfig-windows'
        }
    }
}

# Install WinGet apps

Install-WinGet "PowerShell" "Microsoft.PowerShell"
Install-WinGet "OhMyPosh" "JanDeDobbeleer.OhMyPosh"
Install-WinGet "Git" "Git.Git"
Install-WinGet "fzf" "fzf"
Install-WinGet "jq" "jqlang.jq"

# Install dotnet tools

if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    Install-App "C# REPL" { dotnet tool update -g csharprepl }
}

# Install Rust apps

if (Get-Command "rustup" -ErrorAction SilentlyContinue) {
    Install-App "rust update" { rustup update }
}

if (Get-Command "cargo" -ErrorAction SilentlyContinue) {
    Install-App "atuin" { cargo install --locked atuin --git https://github.com/atuinsh/atuin.git }
    Install-App "bat" { cargo install --locked bat }
    Install-App "delta" { cargo install --locked git-delta }
    Install-App "fd" { cargo install --locked fd-find }
    Install-App "ripgrep" { cargo install --locked ripgrep --features pcre2 }
    Install-App "vivid" { cargo install --locked vivid }
}

# Install PowerShell modules

Install-App "git-completion" { Install-Module git-completion -Force -Scope CurrentUser }

# Reload profile

Write-Header "UPDATING: PowerShell profile"
. "$PSScriptRoot/PowerShell/Profile.ps1" -Update

Write-Header "DONE"
Write-Host ""
