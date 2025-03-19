#!/bin/bash
set -eu

function exec_usershell() {
  cd "${LOCAL_HOME}"
  exec sudo -u ${LOCAL_WHOAMI} /bin/bash
}

USER_ID=${LOCAL_UID:-9001}
GROUP_ID=${LOCAL_GID:-9001}

getent passwd ${LOCAL_WHOAMI} > /dev/null && exec_usershell

########################################################################################################################
# ユーザー作成
########################################################################################################################
echo "Starting with UID : $USER_ID, GID: $GROUP_ID"
# Windowsの場合はdockerグループのGIDをホスト側に合わせる
# Macの場合はホスト側にdockerグループは存在しないため不要
# see: https://forums.docker.com/t/no-more-docker-group/9123/3
test -z "${LOCAL_DOCKER_GID}" || groupmod -g "${LOCAL_DOCKER_GID}" docker
useradd -u $USER_ID -o -m ${LOCAL_WHOAMI}
# Windowsの場合はホスト側のユーザーのGIDに合わせる
test -z "${LOCAL_DOCKER_GID}" || groupmod -g $GROUP_ID ${LOCAL_WHOAMI}
passwd -d ${LOCAL_WHOAMI}
usermod -L ${LOCAL_WHOAMI}
gpasswd -a ${LOCAL_WHOAMI} docker
chown root:docker /var/run/docker.sock
chmod 660 /var/run/docker.sock
chown -R ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} /etc/dotfiles
echo "${LOCAL_WHOAMI} ALL=NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo

# homeディレクトが /home/${LOCAL_WHOAMI} でない場合は変更
# see: https://zenn.dev/hinoshiba/articles/workstation-on-docker#macos%E3%81%AF%E3%80%81%2Fusers%2F%3Cuser%3E-%E3%81%AA%E3%81%AE%E3%81%A7%E3%80%82
chown ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} "${LOCAL_HOME}"
test "${LOCAL_HOME}" == "/home/${LOCAL_WHOAMI}" || (rm -rf "/home/${LOCAL_WHOAMI}" && ln -s "${LOCAL_HOME}" "/home/${LOCAL_WHOAMI}" && usermod -d "${LOCAL_HOME}" "${LOCAL_WHOAMI}")

mv /root/go /home/${LOCAL_WHOAMI}/go && chown -R ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} /home/${LOCAL_WHOAMI}/go

mv /root/.cargo /home/${LOCAL_WHOAMI}/.cargo && chown -R ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} /home/${LOCAL_WHOAMI}/.cargo
mv /root/.rustup /home/${LOCAL_WHOAMI}/.rustup && chown -R ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} /home/${LOCAL_WHOAMI}/.rustup

mv /root/.volta /home/${LOCAL_WHOAMI}/.volta && chown -R ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} /home/${LOCAL_WHOAMI}/.volta

mv /opt/tfenv /home/${LOCAL_WHOAMI}/.tfenv && chown -R ${LOCAL_WHOAMI}:${LOCAL_WHOAMI} /home/${LOCAL_WHOAMI}/.tfenv

########################################################################################################################
# shared directory
########################################################################################################################
# NOTE: docker run時にファイルの有無を確認して必要に応じてファイルを作りたい。
#       Dockerfileだと1度実行後はキャッシュされて実行されないためエントリポイントで毎回実行する
# bash_history
test -d /home/${LOCAL_WHOAMI}/.shared_cache/bash/ || mkdir -p /home/${LOCAL_WHOAMI}/.shared_cache/bash/
test -f /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history || touch /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history && chmod 600 /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history
ln -s /home/${LOCAL_WHOAMI}/.shared_cache/bash/bash_history /home/${LOCAL_WHOAMI}/.bash_history

# volta
# voltaの永続化 & シンボリックリンクの向き先変更
test -d /home/${LOCAL_WHOAMI}/.shared_cache/.volta/ || mv /home/${LOCAL_WHOAMI}/.volta /home/${LOCAL_WHOAMI}/.shared_cache/.volta/ &&\
                                                       ln -nfs volta-shim /home/${LOCAL_WHOAMI}/.shared_cache/.volta/bin/node &&\
                                                       ln -nfs volta-shim /home/${LOCAL_WHOAMI}/.shared_cache/.volta/bin/npm &&\
                                                       ln -nfs volta-shim /home/${LOCAL_WHOAMI}/.shared_cache/.volta/bin/npx &&\
                                                       ln -nfs volta-shim /home/${LOCAL_WHOAMI}/.shared_cache/.volta/bin/pnpm &&\
                                                       ln -nfs volta-shim /home/${LOCAL_WHOAMI}/.shared_cache/.volta/bin/yarn

########################################################################################################################
# シンボリックリンク作成
########################################################################################################################
# vim
mkdir -p /home/${LOCAL_WHOAMI}/.vim/ && \
  ln -s /etc/dotfiles/.vim/vimrc /home/${LOCAL_WHOAMI}/.vim/ && \
  mkdir -p /home/${LOCAL_WHOAMI}/.vim/autoload/ && \
  curl -fLo /home/${LOCAL_WHOAMI}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p /home/${LOCAL_WHOAMI}/.vim/config && \
  for file in $(find /etc/dotfiles/.vim/config/ -type f); do ln -s ${file} /home/${LOCAL_WHOAMI}/.vim/config; done
mkdir -p /home/${LOCAL_WHOAMI}/.vim/snippets && \
  for file in /etc/dotfiles/.vim/snippets/*; do ln -s ${file} /home/${LOCAL_WHOAMI}/.vim/snippets; done
# bash
ln -sf /etc/dotfiles/.bashrc /home/${LOCAL_WHOAMI}/ && \
  ln -sf /etc/dotfiles/.bash_profile /home/${LOCAL_WHOAMI}/ && \
  ln -s /etc/dotfiles/.bashrc_local /home/${LOCAL_WHOAMI}/ && \
  ln -s /etc/dotfiles/.tmux.conf /home/${LOCAL_WHOAMI}/
# bin
sudo ln -s /etc/dotfiles/bin/ide /usr/local/bin/
sudo ln -s /etc/dotfiles/bin/clip /usr/local/bin/

exec_usershell
