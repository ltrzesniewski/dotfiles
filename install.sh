#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"

function startInstall() {
    echo
    echo -e "\e[0;1;33mINSTALLING: $1\e[0m"
}

# Install packages

if command -v apt &> /dev/null; then
    # Required by atuin
    startInstall protoc
    command -v protoc &> /dev/null || dpkg-query -Wf'${db:Status-abbrev}' protobuf-compiler &> /dev/null || sudo apt update && sudo apt install -y protobuf-compiler
fi

# Setup scripts

grep -qF '~/dotfiles/.bashrc' ~/.bashrc || echo 'source ~/dotfiles/.bashrc' >> ~/.bashrc
ln -sf ~/dotfiles/.inputrc ~/.inputrc

# Install oh-py-posh

startInstall OhMyPosh
mkdir -p ~/bin

wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O ~/bin/oh-my-posh
chmod +x ~/bin/oh-my-posh

# Install dotnet tools

startInstall "C# REPL"
command -v dotnet &> /dev/null && dotnet tool update -g csharprepl

# Install Rust apps

startInstall "rust update"
command -v rustup &> /dev/null && rustup update stable

if command -v cargo &> /dev/null; then
    startInstall atuin
    cargo install atuin

    startInstall bat
    cargo install bat

    startInstall btm
    cargo install bottom

    startInstall fd
    cargo install fd-find

    startInstall ripgrep
    cargo install ripgrep --features pcre2
fi

echo
echo -e "\e[0;1;33mDONE\e[0m"
