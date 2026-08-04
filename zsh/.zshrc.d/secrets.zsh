# 1Password CLI経由でシークレットを遅延読み込み（初回参照時にTouch IDで認証）
function ensure_opencode_api_key() {
    if [ -z "$OPENCODE_API_KEY" ]; then
        export OPENCODE_API_KEY=$(op read "op://Development/opencode_zen/credential")
    fi
}

function pi() {
    ensure_opencode_api_key
    command pi "$@"
}
