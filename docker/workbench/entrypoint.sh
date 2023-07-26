#!/bin/bash
set -eu

########################################################################################################################
# shared directory
########################################################################################################################
# NOTE: docker run時にファイルの有無を確認して必要に応じてファイルを作りたい。
#       Dockerfileだと1度実行後はキャッシュされて実行されないためエントリポイントで毎回実行する
# bash_history
test -d /home/${LOCAL_WHOAMI}/.shared_cache/bash/ || mkdir -p /home/${LOCAL_WHOAMI}/.shared_cache/bash/
test -f /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history || touch /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history && chmod 600 /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history
ln -s /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history /home/${LOCAL_WHOAMI}/.bash_history

/bin/bash
