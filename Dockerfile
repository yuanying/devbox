
FROM ubuntu:18.04 as base

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
        libgdbm5 \
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
    useradd -G docker -g 50 -m -s /bin/bash  -u 501 "$USER" && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

FROM base as user_base

USER "$USER"
ENV HOME="/home/$USER"

# install tmux plugins
FROM ubuntu:18.04 as tmux_plugins_builder

RUN apt-get update && apt-get install -y git ca-certificates
RUN mkdir -p /root/.tmux/plugins && cd /root/.tmux/plugins && \
    git clone https://github.com/jonmosco/kube-tmux

# install kubectl
FROM ubuntu:18.04 as kubectl_builder

ENV KUBE_VER v1.17.2
RUN apt-get update && apt-get install -y curl ca-certificates
RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64/kubectl
RUN chmod 755 /usr/local/bin/kubectl

ENV KUSTOMIZE_VER v3.4.0
RUN curl -L -o /tmp/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VER}/kustomize_${KUSTOMIZE_VER}_linux_amd64.tar.gz && \
    tar zxvf /tmp/kustomize.tar.gz -C /usr/local/bin
RUN chmod 755 /usr/local/bin/kustomize

ENV ETCD_VER v3.3.18
ENV DOWNLOAD_URL=https://storage.googleapis.com/etcd
RUN curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz && \
    tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1

ENV HELM_VER v3.0.0
RUN curl -L https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz -o /tmp/helm.tar.gz && \
    tar xzvf /tmp/helm.tar.gz -C /usr/local/bin --strip-components=1

# install 1password
FROM ubuntu:18.04 as onepassword_builder
RUN apt-get update && apt-get install -y curl ca-certificates unzip
RUN curl -sS -o 1password.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_linux_amd64_v0.5.5.zip && unzip 1password.zip op -d /usr/bin &&  rm 1password.zip

# docker builder
FROM docker:19.03 as docker_builder

# golang builder
FROM golang:1.13 as golang_builder
RUN go get -u golang.org/x/tools/gopls
RUN go get -u github.com/nsf/gocode
RUN go get github.com/x-motemen/ghq
ENV PECO_VERSION=v0.5.7
RUN curl -L -o /tmp/peco.tar.gz https://github.com/peco/peco/releases/download/${PECO_VERSION}/peco_linux_amd64.tar.gz && \
    tar zxvf /tmp/peco.tar.gz --strip-components 1 && \
    mv peco /go/bin

# ruby builder
FROM user_base as ruby_builder
RUN sudo git clone https://github.com/rbenv/ruby-build.git
RUN sudo mkdir -p /opt/ruby && sudo ruby-build/bin/ruby-build 2.7.0 /opt/ruby

# vim builder
FROM base as vim_builder
RUN git clone https://github.com/vim/vim.git && \
    cd vim && \
    git checkout v8.2.0200 && \
    ./configure \
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
    make install

# main
FROM user_base as main

# golang
COPY --from=golang_builder /usr/local/go /usr/local/go
RUN sudo chown -R $USER:staff /usr/local/go
COPY --from=golang_builder /go/bin /go/bin
RUN sudo chown -R $USER:staff /go/bin

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

# tmux plugins
COPY --from=tmux_plugins_builder /root/.tmux/plugins $HOME/.tmux/plugins
RUN sudo chown -R $USER:staff $HOME/.tmux

# kubectl
COPY --from=kubectl_builder /usr/local/bin/kubectl /usr/local/bin/
COPY --from=kubectl_builder /usr/local/bin/kustomize /usr/local/bin/
COPY --from=kubectl_builder /usr/local/bin/etcdctl /usr/local/bin/
COPY --from=kubectl_builder /usr/local/bin/helm /usr/local/bin/

# ruby
COPY --from=ruby_builder /opt/ruby /opt/ruby
RUN sudo chown -R $USER:staff /opt/ruby

# vim
COPY --from=vim_builder /opt/vim /opt/vim

# onepassword
COPY --from=onepassword_builder /usr/bin/op /usr/local/bin/

# docker
COPY --from=docker_builder /usr/local/bin/docker /usr/local/bin/

RUN mkdir -p $HOME/bin
COPY pull-secrets.sh $HOME/bin/pull-secrets.sh
COPY link-secrets.sh $HOME/bin/link-secrets.sh
RUN git clone https://github.com/ahmetb/kubectx.git ~/.kubectx && \
    cp ~/.kubectx/kubectx ~/bin/ && chmod +x ~/bin/kubectx && \
    cp ~/.kubectx/kubens ~/bin/ && chmod +x ~/bin/kubens && \
    mkdir -p ~/.zsh/zsh-completions && \
    sudo ln -sf ~/.kubectx/completion/kubectx.zsh /usr/local/share/zsh/site-functions/_kubectx && \
    sudo ln -sf ~/.kubectx/completion/kubens.zsh /usr/local/share/zsh/site-functions/_kubens

COPY entrypoint.sh /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]
