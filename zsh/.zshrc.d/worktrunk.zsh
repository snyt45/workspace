# worktrunk (wt) シェル統合 + ws ラッパー
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# wt switch ラッパー: 引数なしで picker、引数ありでブランチが無ければ自動 create
ws() {
    if [[ $# -eq 0 ]]; then
        wt switch
        return
    fi
    local first=$1
    case "$first" in
        -|@|^|pr:*|mr:*|--*) wt switch "$@"; return ;;
    esac
    shift
    if git rev-parse --verify --quiet "$first" >/dev/null 2>&1; then
        wt switch "$first" "$@"
    else
        wt switch --create "$first" "$@"
    fi
}
