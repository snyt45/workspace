FROM ubuntu:24.04 AS builder
# apt高速化
RUN sed -i 's@archive.ubuntu.com@ftp.jaist.ac.jp/pub/Linux@g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    build-essential

FROM builder AS vim_builder
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      libncurses-dev && \
    cd /tmp && \
    git clone https://github.com/vim/vim.git && \
    cd vim && \
    ./configure \
    --with-features=huge \
    --enable-multibyte \
    --prefix=/usr/local && \
    make && \
    make install

FROM builder AS go_builder
RUN wget https://go.dev/dl/go$(curl -s https://raw.githubusercontent.com/hinoshiba/dockerfiles/master/version/golang/strict).linux-$(dpkg --print-architecture).tar.gz && \
    rm -rf /usr/local/go && tar xzf go$(curl -s https://raw.githubusercontent.com/hinoshiba/dockerfiles/master/version/golang/strict).linux-$(dpkg --print-architecture).tar.gz -C /usr/local && \
    export PATH="${PATH}:/usr/local/go/bin" && \
    go install github.com/gohugoio/hugo@latest

FROM builder AS rust_builder
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup component add rustfmt && \
    rustup component add rust-analyzer

FROM builder AS python_builder
RUN apt-get update && apt-get install -y python3-venv python3-pip
# atcoder環境
RUN python3 -m venv /opt/py_envs && \
    . /opt/py_envs/bin/activate && \
    pip3 install setuptools && \
    pip3 install online-judge-tools

FROM builder AS node_builder
# volta
RUN curl https://get.volta.sh | bash
ENV PATH="/root/.volta/bin:${PATH}"
RUN volta install node && \
    volta install yarn@1.22.19 && \
    volta install npm

FROM builder AS tool_builder
# starship
RUN sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
# lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf lazygit.tar.gz -C /usr/local/bin lazygit
# diff-so-fancy
RUN DIFF_SO_FANCY_VERSION=$(curl -s https://api.github.com/repos/so-fancy/diff-so-fancy/releases/latest | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -L -o diff-so-fancy "https://github.com/so-fancy/diff-so-fancy/releases/download/v${DIFF_SO_FANCY_VERSION}/diff-so-fancy" && \
    mv diff-so-fancy /usr/local/bin/diff-so-fancy && \
    chmod +x /usr/local/bin/diff-so-fancy
# aws cli
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip awscliv2.zip && \
    ./aws/install && \
    AWS_VERSION=$(ls -1 /usr/local/aws-cli/v2/ | grep -v "current") && \
    ln -sf /usr/local/aws-cli/v2/$AWS_VERSION/bin/aws /usr/local/bin/aws
# tfenv
RUN git clone https://github.com/tfutils/tfenv.git /opt/tfenv

FROM builder AS workbench
# 日本語locale
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
# docker-outside-of-docker
# ref: https://matsuand.github.io/docs.docker.jp.onthefly/engine/install/ubuntu/
RUN apt-get update && \
    apt-get install -y \
      sudo \
      ca-certificates \
      gnupg \
      lsb-release && \
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
     echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      tmux \
      fzf \
      ripgrep \
      zoxide \
      lldb \
      universal-ctags \
      gh \
      jq

COPY --from=vim_builder /usr/local /usr/local
COPY --from=vim_builder /usr/local/share/vim /usr/local/share/vim
RUN ln -sf /usr/local/bin/vim /usr/local/bin/vi

COPY --from=go_builder /root/go /root/go
COPY --from=go_builder /usr/local/go /usr/local/go

COPY --from=rust_builder /root/.cargo /root/.cargo
COPY --from=rust_builder /root/.rustup /root/.rustup

COPY --from=python_builder /opt/py_envs /opt/py_envs

COPY --from=node_builder /root/.volta /root/.volta

COPY --from=tool_builder /usr/local/bin/starship /usr/local/bin/starship
COPY --from=tool_builder /usr/local/bin/lazygit /usr/local/bin/lazygit
COPY --from=tool_builder /usr/local/bin/diff-so-fancy /usr/local/bin/diff-so-fancy
COPY --from=tool_builder /usr/local/aws-cli /usr/local/aws-cli
RUN AWS_VERSION=$(ls -1 /usr/local/aws-cli/v2/ | grep -v "current") && \
    ln -sf /usr/local/aws-cli/v2/$AWS_VERSION/bin/aws /usr/local/bin/aws
COPY --from=tool_builder /opt/tfenv /opt/tfenv

########################################################################################################################
# ファイル追加・権限
########################################################################################################################
ADD ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ADD ./dotfiles /etc/dotfiles
RUN chmod +x /etc/dotfiles/bin/ide
RUN chmod +x /etc/dotfiles/bin/clip

# docker run実行時に毎回実行する
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
