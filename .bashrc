
alias ll='ls -alF'

test -f ~/.cargo/env && source ~/.cargo/env

command -v oh-my-posh &> /dev/null && eval "$(oh-my-posh init bash --config ~/dotfiles/prompt.omp.json)"
command -v kubectl &> /dev/null && source <(kubectl completion bash)

if [ -n "$WSL_DISTRO_NAME" ]; then
    export RIPGREP_CONFIG_PATH=~/dotfiles/.ripgreprc-wsl
else
    export RIPGREP_CONFIG_PATH=~/dotfiles/.ripgreprc
fi

export LS_COLORS=$LS_COLORS:'tw=00;33:ow=01;33:'
export BASH_COMPLETION_USER_DIR=~/dotfiles/bash

source ~/dotfiles/bash/.bash-preexec.sh
command -v atuin &> /dev/null && source <(atuin init bash --disable-up-arrow)
