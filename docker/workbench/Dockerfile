# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# ★base-image
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# NOTE: 基本的な設定はここで行う。変更が入ると後続のキャッシュが効かなくなるので極力変更が入らないレイヤーにする
#       ビルドした成果物を最終イメージのみに含めて最終イメージを軽量化する使い方ではなく単純にレイヤーを分けて変更が少ない箇所と多い箇所を分けることが目的。
FROM ubuntu:23.04 AS base-image

ARG local_docker_gid

# apt高速化
RUN sed -i 's@archive.ubuntu.com@ftp.jaist.ac.jp/pub/Linux@g' /etc/apt/sources.list
# 日本語locale
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
# docker-outside-of-docker
# ref: https://matsuand.github.io/docs.docker.jp.onthefly/engine/install/ubuntu/
RUN apt-get update && \
    apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release && \
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
     echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# dockerグループのgidをホストと同じにする
RUN groupmod -g ${local_docker_gid} docker

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# ★workbench
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# NOTE: workbenchに必要なライブラリ等のインストールを行うレイヤー
FROM base-image AS workbench

ARG local_uid=9001
ARG local_gid=9001
ARG local_home
ARG local_whoami
ARG password=password

########################################################################################################################
# apt install
########################################################################################################################
# rootユーザーで実施。この後作成するユーザーだとライブラリによってインストールが進行しないことがあったため。
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      sudo \
      curl \
      wget \
      unzip \
      trash-cli \
      git \
      vim \
      tmux \
      fzf \
      ripgrep \
      bat \
      zoxide \
      golang && \
      apt-get clean && rm -rf /var/lib/apt/lists/*

########################################################################################################################
# ユーザー作成 & 切替
########################################################################################################################
# ubuntu 23.04ではUID・GIDが1000のユーザーが既に存在するためIDを変更しておく
RUN usermod -u 9999 ubuntu && groupmod -g 9999 ubuntu
# rootユーザーのパスワードをrootに設定。rootユーザーに切替えたいとき用。
RUN echo "root:root" | chpasswd
# ホストと同じユーザーグループ作成(gid: ${local_gid}、グループ名: ${local_whoami})
RUN groupadd -g ${local_gid} ${local_whoami}
# ユーザー作成(uidが同じユーザーの作成を許す、ホームディレクトリ作成する、uid: ${local_uid}、gid(primary): ${local_gid}、 gid(secondary): sudo、ユーザー名: ${local_whoami})
RUN useradd -o -m -u ${local_uid} -g ${local_gid} -G sudo ${local_whoami}
# ユーザーのパスワードを${password}に設定
RUN echo ${local_whoami}:${password} | chpasswd
# ユーザーがパスワードなしでsudoコマンドを実行できるようにする
RUN echo "${local_whoami} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# ユーザーをdockerグループに追加
RUN gpasswd -a ${local_whoami} docker

USER ${local_whoami}
WORKDIR /home/${local_whoami}/

########################################################################################################################
# ソフトウェアインストール
########################################################################################################################
# starship
RUN sudo sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
# volta
RUN ["/bin/bash", "-l", "-c", "curl https://get.volta.sh | bash"]
RUN ["/bin/bash", "-l", "-c", "volta install node"]
RUN ["/bin/bash", "-l", "-c", "volta install yarn"]
# lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[0-39.]+') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    sudo tar xf lazygit.tar.gz -C /usr/local/bin lazygit
# delta
RUN sudo wget https://github.com/dandavison/delta/releases/download/0.14.0/delta-0.14.0-x86_64-unknown-linux-musl.tar.gz && \
    sudo tar -zxvf delta-0.14.0-x86_64-unknown-linux-musl.tar.gz && \
    cd delta-0.14.0-x86_64-unknown-linux-musl && \
    sudo mv ./delta /usr/local/bin
# rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# rustfmt
RUN ["/bin/bash", "-l", "-c", "rustup component add rustfmt"]

########################################################################################################################
# ファイル追加・権限
########################################################################################################################
ADD ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sudo chmod +x /usr/local/bin/entrypoint.sh
ADD ./dotfiles /etc/dotfiles
RUN sudo chmod +x /etc/dotfiles/bin/ide
RUN sudo chmod +x /etc/dotfiles/bin/clip
RUN sudo chown -R ${local_whoami}:${local_whoami} /etc/dotfiles

########################################################################################################################
# シンボリックリンク作成
########################################################################################################################
# bat
RUN sudo ln -s /usr/bin/batcat /usr/local/bin/bat
# vim
RUN mkdir -p /home/${local_whoami}/.vim/ && \
    ln -s /etc/dotfiles/.vim/vimrc /home/${local_whoami}/.vim/ && \
    mkdir -p /home/${local_whoami}/.vim/autoload/ && \
    curl -fLo /home/${local_whoami}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
RUN mkdir -p /home/${local_whoami}/.vim/config && \
    for file in /etc/dotfiles/.vim/config/*; do ln -s ${file} /home/${local_whoami}/.vim/config; done
RUN mkdir -p /home/${local_whoami}/.vim/snippets && \
    for file in /etc/dotfiles/.vim/snippets/*; do ln -s ${file} /home/${local_whoami}/.vim/snippets; done
# bash
RUN ln -sf /etc/dotfiles/.bashrc /home/${local_whoami}/ && \
    ln -sf /etc/dotfiles/.bash_profile /home/${local_whoami}/ && \
    ln -s /etc/dotfiles/.bashrc_local /home/${local_whoami}/ && \
    ln -s /etc/dotfiles/.tmux.conf /home/${local_whoami}/
# bin
RUN sudo ln -s /etc/dotfiles/bin/ide /usr/local/bin/
RUN sudo ln -s /etc/dotfiles/bin/clip /usr/local/bin/
# lazygit
RUN mkdir -p /home/${local_whoami}/.config/lazygit && \
    ln -s /etc/dotfiles/.config/lazygit/config.yml /home/${local_whoami}/.config/lazygit

# docker run実行時に毎回実行する
# docker run時に環境変数やdocker.sockをマウントするため、このタイミングでdocker.sockなどに対して設定している
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
