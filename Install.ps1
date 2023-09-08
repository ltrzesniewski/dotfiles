
# Add profile script

if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

if (!(Select-String -Path $PROFILE -Pattern "~/dotfiles/Microsoft.PowerShell_profile.ps1" -Quiet)) {
    Add-Content -Path $PROFILE -Value ". ~/dotfiles/Microsoft.PowerShell_profile.ps1"
}

# Install apps

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
    cargo install bat bottom fd-find
}

# Get rid of the VSCode confirmation dialog
New-Item -Path "HKCU:\Software\Classes\vscode-custom\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\vscode-custom" -Name "URL Protocol" -Value ""
Set-ItemProperty -Path "HKCU:\Software\Classes\vscode-custom\shell\open\command" -Name "(Default)" -Value "wt --window new cmd /c start /min `"`" powershell -ExecutionPolicy Unrestricted -WindowStyle hidden `"$PSScriptRoot\PowerShell\vscode-custom.ps1`" `"%1`""

Write-Output ""
Write-Output "Done"
