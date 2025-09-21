
alias ll='ls -alF'
alias rm-binobj='find -type d \( -name bin -o -name obj \) -exec rm -r {} +'

test -f ~/.cargo/env && source ~/.cargo/env

command -v ~/bin/oh-my-posh &> /dev/null && eval "$(~/bin/oh-my-posh init bash --config ~/dotfiles/prompt.omp.json)"
command -v kubectl &> /dev/null && source <(kubectl completion bash)

if [ -n "$WSL_DISTRO_NAME" ]; then
    export RIPGREP_CONFIG_PATH=~/dotfiles/.ripgreprc-wsl
else
    export RIPGREP_CONFIG_PATH=~/dotfiles/.ripgreprc
fi

command -v rg &> /dev/null && source <(rg --generate complete-bash)

export LS_COLORS=$LS_COLORS:'tw=00;33:ow=01;33:'
export BASH_COMPLETION_USER_DIR=~/dotfiles/bash
export ATUIN_CONFIG_DIR=~/dotfiles/atuin

source ~/dotfiles/bash/.bash-preexec.sh
command -v atuin &> /dev/null && source <(atuin init bash --disable-up-arrow)
