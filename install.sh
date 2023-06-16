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

echo
echo Done
