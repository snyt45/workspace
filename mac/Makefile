.PHONY: setup
setup: \
	macos-config \
	install-rosetta \
	install-packages \
	install-languages \
	link \
	github-auth
	@echo "セットアップが完了しました。設定後、再起動してください。"

.PHONY: help
help:
	@echo "Mac Setup Commands:"
	@echo "  make setup           - Run all setup tasks"
	@echo "  make macos-config    - Configure macOS system preferences"
	@echo "  make install-rosetta - Install Rosetta 2 for Intel apps"
	@echo "  make install-packages - Install Homebrew packages and apps"
	@echo "  make install-languages - Install programming languages via asdf"
	@echo "  make link            - Create symbolic links for dotfiles"
	@echo "  make github-auth     - Setup GitHub CLI authentication"
	@echo ""
	@echo "Additional Commands:"
	@echo "  make vim        - Build Vim from source"

.PHONY: macos-config
macos-config:
	@./scripts/macos-config.sh

.PHONY: install-rosetta
install-rosetta:
	@./scripts/install-rosetta.sh

.PHONY: install-packages
install-packages:
	@./scripts/install-packages.sh

.PHONY: install-languages
install-languages:
	@./scripts/install-languages.sh

.PHONY: link
link:
	@./scripts/link.sh

.PHONY: github-auth
github-auth:
	@./scripts/github-auth.sh

.PHONY: vim
vim:
	@./scripts/make-vim.sh
