eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

if [[ $(command -v socat > /dev/null; echo $?) == 0 ]]; then
    # Start up the socat forwarder to clip.exe
    # echo "Starting clipboard relay..."
    (socat tcp-listen:8121,fork,bind=0.0.0.0 EXEC:'pbcopy' &) > /dev/null 2>&1
fi

alias g='git'

# bin
export PATH="$HOME/bin:$PATH"

# fzf
export FZF_DEFAULT_OPTS="--ansi -e --prompt='QUERY> ' --layout=reverse --border=rounded --height 100%"

# asdf
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

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
    selected=$(fc -l 1 | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//' | sort -u | fzf --query "$BUFFER")
    if [[ -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=${#BUFFER}
    fi
    zle reset-prompt
}
zle -N history-search-fzf
bindkey '^R' history-search-fzf
