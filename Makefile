.PHONY: setup
setup: macos rosetta packages link skills mcp auth
	@echo "セットアップ完了。再起動してください。"

.PHONY: help
help:
	@echo "make setup     - 全セットアップ実行"
	@echo "make macos     - macOS システム設定"
	@echo "make rosetta   - Rosetta 2 インストール"
	@echo "make packages  - Homebrew パッケージインストール"
	@echo "make link      - シンボリックリンク作成"
	@echo "make skills    - Claude Code スキルインストール"
	@echo "make mcp       - Claude Code MCPサーバ設定"
	@echo "make auth      - GitHub CLI 認証"
	@echo "make vim       - Vim をソースからビルド"

.PHONY: macos
macos:
	@echo "[1/7] macOS システム設定..."
	@./scripts/macos.sh

.PHONY: rosetta
rosetta:
	@echo "[2/7] Rosetta 2..."
	@/usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license

.PHONY: packages
packages:
	@echo "[3/7] Homebrew パッケージ..."
	@brew bundle --file=Brewfile

.PHONY: link
link:
	@echo "[4/7] シンボリックリンク..."
	@./scripts/link.sh

.PHONY: skills
skills:
	@echo "[5/7] Claude Code スキル..."
	@./scripts/skills.sh

.PHONY: mcp
mcp:
	@echo "[6/7] Claude Code MCPサーバ..."
	@./scripts/mcp.sh

.PHONY: auth
auth:
	@echo "[7/7] GitHub CLI 認証..."
	@gh auth status 2>/dev/null || gh auth login

.PHONY: vim
vim:
	@./scripts/vim.sh
