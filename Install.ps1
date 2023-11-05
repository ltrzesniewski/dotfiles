
# Add profile script

if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

if (!(Select-String -Path $PROFILE -Pattern "~/dotfiles/Microsoft.PowerShell_profile.ps1" -Quiet)) {
    Add-Content -Path $PROFILE -Value ". ~/dotfiles/Microsoft.PowerShell_profile.ps1"
}

# Install apps

winget install --source winget --silent Microsoft.Powershell
winget install --source winget --silent JanDeDobbeleer.OhMyPosh

# Install dotnet tools

if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    dotnet tool update -g csharprepl
}

# Install Rust apps

if (Get-Command "rustup" -ErrorAction SilentlyContinue) {
    rustup update stable
}

if (Get-Command "cargo" -ErrorAction SilentlyContinue) {
    cargo install bat
    cargo install bottom
    cargo install fd-find
    cargo install --git https://github.com/BurntSushi/ripgrep.git --features pcre2
}

Write-Output ""
Write-Output "Done"
