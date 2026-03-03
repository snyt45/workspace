# fzf でブランチを選んで checkout
gbc() {
  local branch
  branch=$(git branch -a --sort=-committerdate | grep -v HEAD | fzf | sed -e 's/.* //' -e 's#remotes/[^/]*/##')
  [[ -n "$branch" ]] && git checkout "$branch"
}

# fzf でコミットを選んで show
gls() {
  local hash
  hash=$(git log --pretty=format:"%C(yellow)%h%C(cyan)%x09%an%Creset%x09%C(magenta)%ar%x09%Creset%s" -50 --color=always |
    fzf --ansi --preview 'echo {} | grep -o "[0-9a-f]\{7\}" | xargs git show --color=always' \
      --preview-window=right:60%:wrap |
    grep -o "[0-9a-f]\{7\}")
  [[ -n "$hash" ]] && git show "$hash"
}

# fzf でコミットを選んで fixup
gfixup() {
  local hash
  hash=$(git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7)
  [[ -n "$hash" ]] && git commit --fixup "$hash"
}
