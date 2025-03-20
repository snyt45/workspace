## const
INIT_SHELL=/bin/bash
WORKBENCH=workbench
PLAYWRIGHT=playwright

## args
# makeコマンドの引数
TGT=$(target)
PORT=${port}

## env
# ローカルの環境変数をimport
export USER
export HOME

ifeq ($(TGT), $(WORKBENCH))
	ifeq ($(shell uname), Darwin)
		useropt= -e LOCAL_UID=$(shell id -u ${USER}) -e LOCAL_GID=$(shell id -g ${USER}) -e LOCAL_HOME=$(HOME) -e LOCAL_WHOAMI=$(shell whoami) -e LOCAL_DOCKER_GID=""
	else
		useropt= -e LOCAL_UID=$(shell id -u ${USER}) -e LOCAL_GID=$(shell id -g ${USER}) -e LOCAL_HOME=$(HOME) -e LOCAL_WHOAMI=$(shell whoami) -e LOCAL_DOCKER_GID=$(shell getent group docker | awk  -F: '{print $$3}')
	endif

	useropt+= --mount type=bind,src=$(HOME)/work,dst=$(HOME)/work
	useropt+= --mount type=bind,src=$(HOME)/.shared_cache,dst=$(HOME)/.shared_cache
	useropt+= --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock
	useropt+= --mount type=bind,src=$(HOME)/.ssh,dst=$(HOME)/.ssh
	useropt+= --mount type=bind,src=$(HOME)/.gitconfig,dst=$(HOME)/.gitconfig

	ifneq ($(PORT), )
		useropt+= -p 0.0.0.0:$(PORT):$(PORT)
	endif
endif
ifeq ($(TGT), $(PLAYWRIGHT))
	useropt= -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix
	# マウントオプション work
	useropt+= --mount type=bind,src=$(HOME)/work,dst=$(HOME)/work
endif

.PHONY: all
all: start attach ## [Default] start -> attach の順に実行

.PHONY: repopull
repopull: ## repoをgit pull
	git pull

.PHONY: build
build: repopull ## docker imageをbuild
ifeq ($(TGT), )
	@echo "not set target. usage: make <operation> target=<your target>"
	@exit 1
endif
ifneq ($(shell docker ps -aq -f name="$(TGT)"), )
	@echo "既に同じコンテナが存在します。必ず最新の設定が反映されたコンテナを使うようにするため、コンテナを削除してからbuildを行ってください。"
	@exit 1
endif
ifeq ($(shell docker ps -aq -f name="$(TGT)"), )
	docker image build -t $(USER)/$(TGT) $(TGT)/.
endif

.PHONY: start
start: ## docker containerを起動
ifeq ($(TGT), )
	@echo "not set target. usage: make <operation> target=<your target>"
	@exit 1
endif
ifeq ($(shell docker images -aq "$(USER)/$(TGT)"), )
	make build
endif
# targetと同じコンテナ名が存在しない場合
ifeq ($(shell docker ps -aq -f name="$(TGT)"), )
	docker container run -it --rm --name $(TGT) $(useropt) $(USER)/$(TGT)
	sleep 1
endif

.PHONY: attach
attach: ## targetのdocker containerにattach
ifeq ($(TGT), )
	@echo "not set target. usage: make <operation> target=<your target>"
	@exit 1
endif
	docker exec -it $(TGT) $(INIT_SHELL)

.PHONY: stop
stop: ## targetのdocker containerを削除
ifeq ($(TGT), )
	@echo "not set target. usage: make <operation> target=<your target>"
	@exit 1
endif
ifeq ($(shell docker ps -aq -f name="$(TGT)"), )
	@echo "削除するコンテナが存在しません。"
	@exit 1
endif
ifneq ($(shell docker ps -aq -f name="$(TGT)"), )
	docker rm -f $(shell docker ps -aq -f name="$(TGT)")
endif

.PHONY: clean
clean: ## targetのdocker imageを削除
ifeq ($(TGT), )
	@echo "not set target. usage: make <operation> target=<your target>"
	@exit 1
endif
	docker rmi $(USER)/$(TGT)

.PHONY: allrm
allrm: ## 全てのdocker containerを削除
	docker ps -aq | xargs docker rm

.PHONY: allrmi
allrmi: ## 全てのdocker imageを削除
	docker images -aq | xargs docker rmi

.PHONY: help
	all: help
help: ## ヘルプを表示
	@awk -F ':|##' '/^[^\t].+?:.*?##/ {\
		printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
	}' $(MAKEFILE_LIST)
