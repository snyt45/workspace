alias t='tmux'
alias tn='tmux new -s'
alias td='tmux detach'
alias tl='tmux ls'
alias tk='tmux kill-session -t'

# tmux内で別セッションに切り替え
ts() {
  local session
  session=$(tmux ls -F '#S' 2>/dev/null | fzf --prompt='switch> ' --height=40%)
  [[ -n "$session" ]] && tmux switch-client -t "$session"
}
