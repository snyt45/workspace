eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

alias g='git'
alias v='nvim'
alias vd='nvim +CodeDiff'
alias vdh='nvim +"CodeDiff history"'

export EDITOR=nvim
export CLAUDE_CODE_NO_FLICKER=1

# bin
export PATH="$HOME/bin:$PATH"

# fzf
export FZF_DEFAULT_OPTS="--ansi -e --prompt='QUERY> ' --layout=reverse --border=rounded --height 100%"

# mise shims: エディタやLSP等の非インタラクティブなツールがmise管理のランタイムを参照できるようにする
export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate zsh)"

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


# zsh-autosuggestions
[ -s /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# 1Password CLI経由でシークレットを遅延読み込み（初回参照時にTouch IDで認証）
function ensure_anthropic_api_key() {
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        export ANTHROPIC_API_KEY=$(op read "op://Development/anthropic/credential")
    fi
}

for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done
