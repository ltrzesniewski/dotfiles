
alias ll='ls -alF'

test -f ~/.cargo/env && source ~/.cargo/env
command -v kubectl &> /dev/null && source <(kubectl completion bash)
command -v oh-my-posh &> /dev/null && eval "$(oh-my-posh init bash --config ~/dotfiles/prompt.omp.json)"
