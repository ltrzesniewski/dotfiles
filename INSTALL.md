# Common

Clone in `$HOME/dotfiles`

# Windows

Execute:

```pwsh
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted

winget install JanDeDobbeleer.OhMyPosh -s winget
```

Execute as admin:

```pwsh
oh-my-posh font install

Install-Module -Name Terminal-Icons -Repository PSGallery
```

Add to `$PROFILE`:

```pwsh
. $HOME/dotfiles/Microsoft.PowerShell_profile.ps1
```

# WSL

To share the `dotfiles` repo with Windows:

```bash
ln -s /mnt/c/Users/Lucas/dotfiles dotfiles
```

# Linux

Execute:

```bash
sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

ln -s ~/dotfiles/.inputrc ~/.inputrc
```

Add to `.bashrc`:

```bash
source ~/dotfiles/.bashrc
```
