eval "$(zoxide init zsh)"

# mise shims: エディタやLSP等の非インタラクティブなツールがmise管理のランタイムを参照できるようにする
export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate zsh)"

# zsh-autosuggestions
[ -s /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
