
FROM ubuntu:20.04 as base

ENV DEBIAN_FRONTEND=noninteractive

# Install build-essential etc
RUN set -x -e && \
    apt-get update && \
    apt-get install -y \
        apt-utils \
        autoconf \
        bison \
        build-essential \
        ca-certificates \
        curl \
        file \
        git \
        iputils-ping \
        jq \
        libbz2-dev \
        libffi-dev \
        libgdbm-dev \
        libgdbm6 \
        libncurses5-dev \
        libreadline6-dev \
        libsqlite3-dev \
        libssl-dev \
        libyaml-dev \
        locales \
        mosh \
        net-tools \
        openssh-server \
        strace \
        tmux \
        wget \
        zlib1g-dev \
        zsh

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
	locale-gen --purge $LANG && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=$LANG LC_ALL=$LC_ALL LANGUAGE=$LANGUAGE

COPY etc/apt/apt.conf.d/01norecommend /etc/apt/apt.conf.d/01norecommend

RUN mkdir /run/sshd
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN sed 's/#Port 22/Port 3222/' -i /etc/ssh/sshd_config

# Create a user
ENV USER=dev
RUN set -x -e && \
    apt-get update && \
    apt-get -y install sudo && \
    groupadd -g 999 docker && \
    groupadd -g 998 docker2 && \
    useradd -G docker,docker2 -g 50 -m -s /bin/bash  -u 501 "$USER" && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

FROM base as user_base

USER "$USER"
ENV HOME="/home/$USER"

# install 1password
FROM ubuntu:20.04 as onepassword_builder
RUN apt-get update && apt-get install -y curl ca-certificates unzip
RUN curl -sS -o 1password.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_linux_amd64_v0.5.5.zip && unzip 1password.zip op -d /usr/bin &&  rm 1password.zip

# docker builder
FROM docker:19.03 as docker_builder

# golang builder
FROM golang:1.13 as golang_builder
RUN go get -u golang.org/x/tools/gopls
RUN go get -u golang.org/x/tools/cmd/goimports
RUN go get -u github.com/nsf/gocode
RUN go get github.com/x-motemen/ghq
ENV PECO_VERSION=v0.5.7
RUN curl -L -o /tmp/peco.tar.gz https://github.com/peco/peco/releases/download/${PECO_VERSION}/peco_linux_amd64.tar.gz && \
    tar zxvf /tmp/peco.tar.gz --strip-components 1 && \
    mv peco /go/bin
RUN curl -L -o docker-buildx https://github.com/docker/buildx/releases/download/v0.4.1/buildx-v0.4.1.linux-amd64 && \
    chmod +x docker-buildx && \
    mv docker-buildx /usr/local/lib

# vim builder
FROM base as vim_builder
RUN sudo git clone https://github.com/vim/vim.git && \
    cd vim && \
    sudo git checkout v8.2.0200 && \
    sudo ./configure \
        --prefix=/opt/vim/ \
        --enable-multibyte \
        --enable-nls \
        --enable-cscope \
        --enable-fail-if-missing=yes \
        --with-features=huge \
        --without-x \
        --disable-xim \
        --disable-gui \
        --disable-sysmouse \
        --disable-netbeans \
        --disable-xsmp && \
    sudo make install

# code-server builder
FROM user_base as code_builder
RUN mkdir -p /home/dev/.local/lib /home/dev/.local/bin && \
    curl -fL https://github.com/cdr/code-server/releases/download/v3.4.1/code-server-3.4.1-linux-amd64.tar.gz \
      | tar -C /home/dev/.local/lib -xz && \
    mv /home/dev/.local/lib/code-server-3.4.1-linux-amd64 /home/dev/.local/lib/code-server-3.4.1 && \
    ln -s /home/dev/.local/lib/code-server-3.4.1/bin/code-server /home/dev/.local/bin/code-server

# main
FROM user_base as main

# Install user applications
RUN set -x -e && \
    sudo apt-get update && \
    sudo apt-get install -y \
        silversearcher-ag

# golang
COPY --from=golang_builder /usr/local/go /usr/local/go
RUN sudo chown -R $USER:staff /usr/local/go
COPY --from=golang_builder /go/bin /go/bin
RUN sudo chown -R $USER:staff /go/bin
RUN sudo mkdir -p /usr/local/lib/docker/cli-plugins
COPY --from=golang_builder /usr/local/lib/docker-buildx /usr/local/lib/docker/cli-plugins/

# Install go tools
ENV GOPATH="/go"
ENV PATH="$GOPATH/bin:$PATH"

# Set default environment variables
ENV EDITOR=vim
ENV GOPATH="$HOME"
ENV GHQ_ROOT="$HOME/src"

# vim plugins
RUN curl -fLo ~/.vim/autoload/plug.vim \
    --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# zsh plugins
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
RUN git clone https://github.com/denysdovhan/spaceship-prompt ~/.zsh/spaceship-prompt

# vim
COPY --from=vim_builder /opt/vim /opt/vim

# onepassword
COPY --from=onepassword_builder /usr/bin/op /usr/local/bin/

# docker
COPY --from=docker_builder /usr/local/bin/docker /usr/local/bin/

# code-server
COPY --from=code_builder /home/dev/.local /home/dev/.local

RUN mkdir -p $HOME/bin
COPY pull-secrets.sh $HOME/bin/pull-secrets.sh
COPY link-secrets.sh $HOME/bin/link-secrets.sh
RUN git clone https://github.com/ahmetb/kubectx.git ~/.kubectx && \
    mkdir -p ~/.zsh/zsh-completions && \
    sudo ln -sf ~/.kubectx/completion/kubectx.zsh /usr/local/share/zsh/site-functions/_kubectx && \
    sudo ln -sf ~/.kubectx/completion/kubens.zsh /usr/local/share/zsh/site-functions/_kubens && \
    ln -sf $HOME/.zsh/spaceship-prompt/spaceship.zsh $HOME/.zsh/zsh-completions/prompt_spaceship_setup
# RUN git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.7.8

COPY entrypoint.sh /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]
