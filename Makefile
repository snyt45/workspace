.PHONY: setup
setup: macos rosetta packages link auth
	@echo "セットアップ完了。再起動してください。"

.PHONY: help
help:
	@echo "make setup     - 全セットアップ実行"
	@echo "make macos     - macOS システム設定"
	@echo "make rosetta   - Rosetta 2 インストール"
	@echo "make packages  - Homebrew パッケージインストール"
	@echo "make link      - シンボリックリンク作成"
	@echo "make auth      - GitHub CLI 認証"
	@echo "make vim       - Vim をソースからビルド"

.PHONY: macos
macos:
	@echo "[1/5] macOS システム設定..."
	@./scripts/macos.sh

.PHONY: rosetta
rosetta:
	@echo "[2/5] Rosetta 2..."
	@/usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license

.PHONY: packages
packages:
	@echo "[3/5] Homebrew パッケージ..."
	@brew bundle --file=Brewfile

.PHONY: link
link:
	@echo "[4/5] シンボリックリンク..."
	@./scripts/link.sh

.PHONY: auth
auth:
	@echo "[5/5] GitHub CLI 認証..."
	@gh auth status 2>/dev/null || gh auth login

.PHONY: vim
vim:
	@./scripts/vim.sh
