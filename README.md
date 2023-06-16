# Config

These are my config files.

This repo is public just for ease of access.

# Install

## Common

 - Clone this repo to `~/dotfiles`
 - Install a [nerd font](https://www.nerdfonts.com/font-downloads) (use the Mono Windows Compatible variant)
   - [Hack](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip)
   - [DejaVu Sans Mono](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/DejaVuSansMono.zip)
 - IDE fonts:
   - [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono)
   - [Source Code Pro](https://github.com/adobe-fonts/source-code-pro/releases/latest)

## Windows

Execute as admin:

```pwsh
./Install.ps1
```

## WSL

To share the `dotfiles` repo with Windows:

```bash
ln -s /mnt/c/Users/$(wslvar USERNAME)/dotfiles dotfiles
```

## Linux

Execute:

```bash
./install.sh
```
