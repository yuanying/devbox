FROM ubuntu:22.04 as base

ENV DEBIAN_FRONTEND=noninteractive

# Install build-essential etc
RUN set -x -e && \
    apt-get update && \
    apt-get install -y \
        apt-utils \
        autoconf \
        automake \
        bison \
        build-essential \
        ca-certificates \
        curl \
        dpkg \
        dnsutils \
        file \
        git \
        iproute2 \
        iputils-ping \
        jq \
        libbz2-dev \
        libc6 \
        libevent-dev \
        libffi-dev \
        libgcc-s1 \
        libgdbm-dev \
        libgdbm6 \
        libio-socket-ip-perl \
        libjpeg-dev \
        liblzma-dev \
        libncurses-dev \
        libopenblas-dev \
        libpng-dev \
        libprotobuf23 \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libssl3 \
        libstdc++6 \
        libtinfo6 \
        libutempter0 \
        libyaml-dev \
        locales \
        net-tools \
        openssh-client \
        openssh-server \
        pkg-config \
        qemu-utils \
        software-properties-common \
        strace \
        wget \
        zlib1g \
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
ENV USER=yuanying
RUN set -x -e && \
    apt-get update && \
    apt-get -y install sudo && \
    groupadd -g 999 docker && \
    groupadd -g 998 docker2 && \
    useradd -G video,docker,docker2 -g 50 -m -s /bin/bash  -u 501 "$USER" && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

FROM base as user_base

USER "$USER"
ENV HOME="/home/$USER"

# docker builder
FROM docker:20.10 as docker_builder

# golang builder
FROM golang:1.20 as golang_builder
RUN go install golang.org/x/tools/gopls@latest
RUN go install golang.org/x/tools/cmd/goimports@latest
RUN go install github.com/nsf/gocode@latest
RUN go install github.com/x-motemen/ghq@latest
RUN go install github.com/jstemmer/gotags@latest
RUN go install github.com/howardjohn/kubectl-resources@latest
RUN go install github.com/gopasspw/gopass@latest
RUN curl -L -o docker-buildx https://github.com/docker/buildx/releases/download/v0.10.4/buildx-v0.10.4.linux-amd64 && \
    chmod +x docker-buildx && \
    mv docker-buildx /usr/local/lib
RUN curl -L -o hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 && \
    chmod +x hey && \
    mv hey /go/bin

# tmux builder
FROM base as tmux_builder
RUN git clone https://github.com/tmux/tmux.git && \
    cd tmux && \
    git checkout 3.2 && \
    sh autogen.sh && \
    ./configure && \
    make && \
    mkdir -p /opt/tmux/bin && \
    mv tmux /opt/tmux/bin

# main
FROM user_base as main

# Install user applications
RUN set -x -e && \
    sudo add-apt-repository -y ppa:keithw/mosh-dev && \
    sudo apt-get update && \
    sudo apt-get install -y \
	    mosh \
        bat \
        fzf \
        silversearcher-ag \
        universal-ctags \
        unzip

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

RUN \
     curl -L https://github.com/neovim/neovim/releases/download/v0.9.0/nvim-linux64.tar.gz | sudo sudo tar zx --strip-components 1 -C /usr;
RUN \
   sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60 && \
   sudo update-alternatives --config vi && \
   sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60 && \
   sudo update-alternatives --config vim && \
   sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60 && \
   sudo update-alternatives --config editor

# tmux
COPY --from=tmux_builder /opt/tmux/bin/tmux /usr/local/bin/

# docker
COPY --from=docker_builder /usr/local/bin/docker /usr/local/bin/

RUN \
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# RUN git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.7.8

COPY entrypoint.sh /bin/entrypoint.sh
RUN sudo chmod +x /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]
