eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

alias g='git'

export EDITOR=vim

# bin
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# fzf
export FZF_DEFAULT_OPTS="--ansi -e --prompt='QUERY> ' --layout=reverse --border=rounded --height 100%"

# asdf
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

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

# karabinerに依存
# tmuxでもキーを動作させる
if [[ -n "$TMUX" ]]; then
  bindkey -e
  bindkey '^[[1~' beginning-of-line # 行頭
  bindkey '^[[4~' end-of-line       # 行末
  bindkey '^[[1;5C' forward-word    # 次の単語へ移動
  bindkey '^[[1;5D' backward-word   # 前の単語へ移動
fi

for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done
