#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"

function startInstall() {
    echo
    echo -e "\e[0;1;33mINSTALLING: $1\e[0m"
}

# Setup scripts

grep -qF '~/dotfiles/.bashrc' ~/.bashrc || echo 'source ~/dotfiles/.bashrc' >> ~/.bashrc
ln -sf ~/dotfiles/.inputrc ~/.inputrc

# Install oh-py-posh

startInstall OhMyPosh
mkdir -p ~/bin

wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O ~/bin/oh-my-posh
chmod +x ~/bin/oh-my-posh

# Install APT packages

if command -v apt &> /dev/null; then
    startInstall "APT packages"
    sudo apt update
    sudo apt dist-upgrade -y
    sudo apt install -y fzf jq
fi

# Install dotnet tools

startInstall "C# REPL"
command -v dotnet &> /dev/null && dotnet tool update -g csharprepl

# Install Rust apps

startInstall "rust update"
command -v rustup &> /dev/null && rustup update

if command -v cargo &> /dev/null; then
    startInstall atuin
    cargo install --locked atuin

    startInstall bat
    cargo install --locked bat

    startInstall btm
    cargo install --locked bottom

    startInstall fd
    cargo install --locked fd-find

    startInstall ripgrep
    cargo install --locked ripgrep --features pcre2
fi

echo
echo -e "\e[0;1;33mDONE\e[0m"
echo
