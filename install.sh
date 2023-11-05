#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"

# Setup scripts

grep -qF '~/dotfiles/.bashrc' ~/.bashrc || echo 'source ~/dotfiles/.bashrc' >> ~/.bashrc
ln -sf ~/dotfiles/.inputrc ~/.inputrc

# Install oh-py-posh

mkdir -p ~/bin

wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O ~/bin/oh-my-posh
chmod +x ~/bin/oh-my-posh

# Install dotnet tools

command -v dotnet &> /dev/null && dotnet tool update -g csharprepl

# Install Rust apps

command -v rustup &> /dev/null && rustup update stable

if command -v cargo &> /dev/null; then
    cargo install atuin
    cargo install bat
    cargo install bottom
    cargo install fd-find
    cargo install --git https://github.com/BurntSushi/ripgrep.git --features pcre2
fi

echo
echo Done
