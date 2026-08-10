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

# cursortab.nvim (Mercury API)
function ensure_inception_api_key() {
    if [ -z "$MERCURY_AI_TOKEN" ]; then
        export MERCURY_AI_TOKEN=$(op read "op://Development/inception/credential")
    fi
}

function nvim() {
    ensure_inception_api_key
    command nvim "$@"
}
