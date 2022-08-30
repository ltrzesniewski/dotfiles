# Config

These are my config files.

This repo is public just for ease of access. Use at your own risk!

# Install

## Common

 - Clone this repo to `~/dotfiles`
 - Install a [nerd font](https://www.nerdfonts.com/font-downloads) (I use Caskaydia Cove for the terminal)

## Windows

Execute:

```pwsh
winget install JanDeDobbeleer.OhMyPosh -s winget
```

Execute as admin:

```pwsh
Install-Module -Name Terminal-Icons -Repository PSGallery
```

Add to `$PROFILE` (`~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`):

```pwsh
. ~/dotfiles/Microsoft.PowerShell_profile.ps1
```

## WSL

To share the `dotfiles` repo with Windows:

```bash
ln -s /mnt/c/Users/[username]/dotfiles dotfiles
```

## Linux

Execute in `~`:

```bash
sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

ln -s dotfiles/.inputrc ~/.inputrc
```

Add to `.bashrc` or `.profile`:

```bash
source ~/dotfiles/.bashrc
```