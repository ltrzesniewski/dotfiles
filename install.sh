#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"

# Install packages

if command -v apt &> /dev/null; then
    # Required by atuin
    command -v protoc &> /dev/null || dpkg-query -Wf'${db:Status-abbrev}' protobuf-compiler &> /dev/null || sudo apt update && sudo apt install -y protobuf-compiler
fi

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
    cargo install ripgrep --features pcre2
fi

echo
echo Done
