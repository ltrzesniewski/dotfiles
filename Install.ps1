
# Get rid of the VSCode confirmation dialog
New-Item -Path "HKCU:\Software\Classes\vscode-custom\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\vscode-custom" -Name "URL Protocol" -Value ""
Set-ItemProperty -Path "HKCU:\Software\Classes\vscode-custom\shell\open\command" -Name "(Default)" -Value "wt --window new cmd /c start /min `"`" powershell -ExecutionPolicy Unrestricted -WindowStyle hidden `"$HOME\dotfiles\PowerShell\vscode-custom.ps1`" `"%1`""

Write-Output "Done"
