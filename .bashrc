
alias ll='ls -alF'

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
export BAT_CONFIG_DIR=~/dotfiles/bat

export FZF_DEFAULT_OPTS='
    --style full:rounded
    --reverse
    --color dark,hl:bright-red:underline,hl+:bright-red:underline
'

source ~/dotfiles/bash/.bash-preexec.sh
command -v atuin &> /dev/null && source <(atuin init bash)

rm_binobj() {
    find -type d \( -name bin -o -name obj \) -prune -exec rm -r {} +
}

fdf() {
    fdf=$(fd --strip-cwd-prefix --color=always "$@" | fzf --ansi --scheme=path --footer="$(pwd)" --preview='bat --color=always --style=plain {} 2> /dev/null || fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}' -m)
    echo "$fdf" # Intentional shadowing
}

fdh() {
    fd --hyperlink=auto "$@"
}

rgr() {
    rg --no-heading --no-filename --no-line-number "$@"
}

rgd() {
    rg --json "$@" | delta
}

cdr() {
    cd "$(git rev-parse --show-toplevel 2> /dev/null || pwd)"
}

cdf() {
    local currentDir="$(pwd)"
    local baseDir="$(git rev-parse --show-toplevel 2> /dev/null || echo "$currentDir")"
    local footer="$([[ "$baseDir" == "$currentDir" ]] && echo "$baseDir" || echo -e "Search:  $baseDir\nCurrent: $currentDir")"
    cd "$baseDir"
    cd "$((echo .; fd --type=d --color=always "${@:-.}") | fzf --ansi --scheme=path --footer="$footer" --preview='fd --max-depth=1 --unrestricted --relative-path --color=always --base-directory {}' || echo "$currentDir")"
}
