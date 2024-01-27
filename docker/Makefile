## const
INIT_SHELL=/bin/bash
WORKBENCH=workbench
PLAYWRIGHT=playwright

## args
# makeコマンドの引数
TGT=$(target)
PORT=${port}
NOCACHE=${nocache}

## env
# ローカルの環境変数をimport
export USER
export HOME

ifeq ($(TGT), $(WORKBENCH))
	## docker build時のオプション
	# 引数 ローカルのuidを渡す
	buildopt= --build-arg local_uid=$(shell id -u ${USER})
	# 引数 ローカルのgidを渡す
	buildopt+= --build-arg local_gid=$(shell id -g ${USER})
	# 引数 ローカルのhomeを渡す
	buildopt+= --build-arg local_home=$(HOME)
	# 引数 ローカルのwhoamiを渡す
	buildopt+= --build-arg local_whoami=$(shell whoami)
	# 引数 ローカルのDockerのgidを渡す
	buildopt+= --build-arg local_docker_gid=$(shell getent group docker | awk -F: '{print $$3}')

	## docker run時のオプション
	# 環境変数 ローカルのwhoamiを渡す
	runopt= -e LOCAL_WHOAMI=$(shell whoami)
	# マウントオプション work
	runopt+= --mount type=bind,src=$(HOME)/work,dst=$(HOME)/work
	# マウントオプション shared_cache
	runopt+= --mount type=bind,src=$(HOME)/.shared_cache,dst=$(HOME)/.shared_cache
	# マウントオプション docker socket
	runopt+= --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock
	# マウントオプション ssh
	runopt+= --mount type=bind,src=$(HOME)/.ssh,dst=$(HOME)/.ssh
	# マウントオプション gitconfig
	runopt+= --mount type=bind,src=$(HOME)/.gitconfig,dst=$(HOME)/.gitconfig
	# マウントオプション clip
	runopt+= --mount type=bind,src=$(HOME)/clip,dst=$(HOME)/clip
	# マウントオプション chrome
	runopt+= --mount type=bind,src=$(HOME)/chrome,dst=$(HOME)/chrome
	# DockerでC++デバッグを有効にする
	# see: https://stackoverflow.com/questions/70108775/gdb-exits-immediately-process-finished-with-exit-code-1-or-lldb-a-packet-ret/70108776#70108776
	runopt+= --cap-add=SYS_PTRACE --security-opt seccomp=unconfined
endif
ifeq ($(TGT), $(PLAYWRIGHT))
	runopt= -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix
	# マウントオプション work
	runopt+= --mount type=bind,src=$(HOME)/work,dst=$(HOME)/work
endif
ifneq ($(PORT), )
	portopt= -p 0.0.0.0:$(PORT):$(PORT)
endif
ifneq ($(NOCACHE), )
	buildopt+= --no-cache
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
	docker image build $(buildopt) -t $(USER)/$(TGT) $(TGT)/.
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
	docker container run -itd --rm --name $(TGT) $(runopt) $(portopt) $(USER)/$(TGT)
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
