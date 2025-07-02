eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

alias g='git'

export EDITOR=vim

# bin
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/work/toypo-terraform/bin:$PATH"

# fzf
export FZF_DEFAULT_OPTS="--ansi -e --prompt='QUERY> ' --layout=reverse --border=rounded --height 100%"

# asdf
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# asdf - golang
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

# Android SDK
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export JVM_ARGS="-Xmx24g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"

# 履歴の重複を避ける
setopt HIST_IGNORE_ALL_DUPS   # 同じコマンドを履歴に残さない
setopt HIST_SAVE_NO_DUPS      # 重複するコマンドを保存しない
setopt HIST_IGNORE_DUPS       # 連続する同じコマンドを無視
setopt HIST_FIND_NO_DUPS      # 履歴検索時に重複を無視
setopt HIST_REDUCE_BLANKS     # 余分な空白を削除してから履歴に追加

# history検索(C-r)
function history-search-fzf() {
    local selected
    selected=$(fc -l 1 | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//' | awk '!seen[$0]++' | tail -r | fzf --query "$BUFFER")
    if [[ -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=${#BUFFER}
    fi
    zle reset-prompt
}
zle -N history-search-fzf
bindkey '^R' history-search-fzf
