ARG GOLANG_VERSION=1.12.1

# install tmux plugins
FROM ubuntu:18.04 as tmux_plugins_builder

RUN apt-get update && apt-get install -y git ca-certificates
RUN mkdir -p /root/.tmux/plugins && cd /root/.tmux/plugins && \
    git clone https://github.com/jonmosco/kube-tmux

# install kubectl
FROM ubuntu:18.04 as kubectl_builder

ENV KUBE_VER v1.15.0
RUN apt-get update && apt-get install -y curl ca-certificates
RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64/kubectl
RUN chmod 755 /usr/local/bin/kubectl

ENV KUSTOMIZE_VER 3.1.0
RUN curl -L -o /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VER}/kustomize_${KUSTOMIZE_VER}_linux_amd64
RUN chmod 755 /usr/local/bin/kustomize

ENV ETCD_VER v3.2.26
ENV DOWNLOAD_URL=https://storage.googleapis.com/etcd
RUN curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz && \
    tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1

ENV HELM_VER v2.13.0
RUN curl -L https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VER}-linux-amd64.tar.gz -o /tmp/helm.tar.gz && \
    tar xzvf /tmp/helm.tar.gz -C /usr/local/bin --strip-components=1


# install 1password
FROM ubuntu:18.04 as onepassword_builder
RUN apt-get update && apt-get install -y curl ca-certificates unzip
RUN curl -sS -o 1password.zip https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_linux_amd64_v0.5.5.zip && unzip 1password.zip op -d /usr/bin &&  rm 1password.zip

# install vim plugins
FROM ubuntu:18.04 as vim_plugins_builder
RUN apt-get update && apt-get install -y git ca-certificates
RUN mkdir -p /root/.vim/plugged && cd /root/.vim/plugged && \
   git clone 'https://github.com/airblade/vim-gitgutter' && \
   git clone 'https://github.com/cespare/vim-toml' && \
   git clone 'https://github.com/cohama/vim-hier' && \
   git clone 'https://github.com/ctrlpvim/ctrlp.vim' && \
   git clone 'https://github.com/dannyob/quickfixstatus' && \
   git clone 'https://github.com/editorconfig/editorconfig-vim' && \
   git clone 'https://github.com/ekalinin/Dockerfile.vim' && \
   git clone 'https://github.com/elzr/vim-json' && \
   git clone 'https://github.com/fatih/molokai' && \
   git clone 'https://github.com/fatih/vim-go' && \
   git clone 'https://github.com/fholgado/minibufexpl.vim' && \
   git clone 'https://github.com/godlygeek/tabular' && \
   git clone 'https://github.com/google/vim-ft-go' && \
   git clone 'https://github.com/hail2u/vim-css3-syntax' && \
   git clone 'https://github.com/heavenshell/vim-jsdoc' && \
   git clone 'https://github.com/itchyny/lightline.vim' && \
   git clone 'https://github.com/junegunn/vim-emoji' && \
   git clone 'https://github.com/junegunn/vim-plug' && \
   git clone 'https://github.com/justmao945/vim-clang' && \
   git clone 'https://github.com/majutsushi/tagbar' && \
   git clone 'https://github.com/mattn/ctrlp-ghq' && \
   git clone 'https://github.com/mattn/gist-vim' && \
   git clone 'https://github.com/mattn/vim-maketable' && \
   git clone 'https://github.com/mattn/webapi-vim' && \
   git clone 'https://github.com/miyakogi/seiya.vim' && \
   git clone 'https://github.com/moll/vim-node' && \
   git clone 'https://github.com/mrtazz/simplenote.vim' && \
   git clone 'https://github.com/mxw/vim-jsx' && \
   git clone 'https://github.com/myhere/vim-nodejs-complete' && \
   git clone 'https://github.com/noahfrederick/vim-skeleton' && \
   git clone 'https://github.com/osyo-manga/shabadou.vim' && \
   git clone 'https://github.com/osyo-manga/vim-watchdogs' && \
   git clone 'https://github.com/othree/eregex.vim' && \
   git clone 'https://github.com/pangloss/vim-javascript' && \
   git clone 'https://github.com/pix/vim-align' && \
   git clone 'https://github.com/plasticboy/vim-markdown' && \
   git clone 'https://github.com/qpkorr/vim-renamer' && \
   git clone 'https://github.com/rafi/vim-unite-issue' && \
   git clone 'https://github.com/scrooloose/nerdcommenter' && \
   git clone 'https://github.com/scrooloose/nerdtree' && \
   git clone 'https://github.com/Shougo/context_filetype.vim' && \
   git clone 'https://github.com/Shougo/neomru.vim' && \
   git clone 'https://github.com/Shougo/neosnippet' && \
   git clone 'https://github.com/Shougo/neosnippet-snippets' && \
   git clone 'https://github.com/Shougo/unite-outline' && \
   git clone 'https://github.com/Shougo/unite.vim' && \
   git clone 'https://github.com/Shougo/vimproc.vim' && \
   git clone 'https://github.com/superbrothers/vim-bclose' && \
   git clone 'https://github.com/thinca/vim-quickrun' && \
   git clone 'https://github.com/tpope/vim-fugitive' && \
   git clone 'https://github.com/tyru/open-browser.vim' && \
   git clone 'https://github.com/ujihisa/unite-colorscheme' && \
   git clone 'https://github.com/vim-ruby/vim-ruby' && \
   git clone 'https://github.com/vim-scripts/sudo.vim' && \
   git clone 'https://github.com/vim-scripts/ViewOutput' && \
   git clone 'https://github.com/vim-scripts/YankRing.vim' && \
   git clone 'https://github.com/Xuyuanp/nerdtree-git-plugin' && \
   git clone 'https://github.com/yegappan/grep' && \
   git clone 'https://github.com/Yggdroot/indentLine'

# install linux brew
FROM ubuntu:18.04 as linuxbrew_installer

RUN set -x -e && \
    apt-get update && \
    apt-get install -y \
        --no-install-recommends \
        build-essential \
        curl \
        sudo \
        ca-certificates \
        locales \
        git

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
	locale-gen --purge $LANG && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=$LANG LC_ALL=$LC_ALL LANGUAGE=$LANGUAGE

# Create a user
ENV USER=dev
RUN set -x -e && \
    useradd -m -s /bin/bash  -u 501 "$USER" && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER "$USER"
ENV HOME="/home/$USER"

# Install Linuxbrew
# https://github.com/Homebrew/brew/blob/master/docs/Linuxbrew.md
RUN set -x -e && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" && \
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && \
    brew --version && \
    brew update

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Install development packages
ARG HOMEBREW_NO_AUTO_UPDATE=1
RUN set -x && brew install docker
RUN set -x && brew install zsh
RUN set -x && brew install vim
RUN set -x && brew install peco
RUN set -x && brew install ghq
RUN set -x && brew install go
RUN set -x && brew install node
RUN set -x && brew install jq
RUN set -x && brew install dep
RUN set -x && brew install rbenv
RUN set -x && brew install pyenv-virtualenv

FROM ubuntu:18.04 as main

# Install build-essential etc
RUN set -x -e && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        apt-utils \
        locales \
        curl \
        file \
        git \
        ca-certificates \
        openssh-server \
        mosh \
        tmux \
        iputils-ping \
        net-tools \
        strace \
        wget \
        zlib1g-dev \
        libffi-dev \
        libbz2-dev \
        libsqlite3-dev

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

USER "$USER"
ENV HOME="/home/$USER"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
# linuxbrew
COPY --from=linuxbrew_installer /home/linuxbrew /home/linuxbrew
RUN sudo chown -R $USER:staff /home/linuxbrew

# Install go tools
ENV GOPATH="/go"
RUN set -x -e && \
    sudo mkdir "$GOPATH" && \
    sudo chown "$USER" "$GOPATH" && \
    export GOCACHE=/tmp/gocache && \
    go get github.com/nsf/gocode && \
    go get github.com/wagoodman/dive && \
    rm -rf "$GOPATH/src" "$GOCACHE"

ENV PATH="$GOPATH/bin:$PATH"

# Set default environment variables
ENV EDITOR=vim
ENV GOPATH="$HOME"
ENV GHQ_ROOT="$HOME/src"

# vim plugins
RUN curl -fLo ~/.vim/autoload/plug.vim \
    --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
COPY --from=vim_plugins_builder /root/.vim/plugged $HOME/.vim/plugged
RUN sudo chown -R $USER:staff $HOME/.vim
RUN cd /home/dev/.vim/plugged/vimproc.vim && make

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

# onepassword
COPY --from=onepassword_builder /usr/bin/op /usr/local/bin/

RUN mkdir -p $HOME/bin
COPY pull-secrets.sh $HOME/bin/pull-secrets.sh
COPY link-secrets.sh $HOME/bin/link-secrets.sh
RUN git clone https://github.com/ahmetb/kubectx.git ~/.kubectx && \
    cp ~/.kubectx/kubectx ~/bin/ && chmod +x ~/bin/kubectx && \
    cp ~/.kubectx/kubens ~/bin/ && chmod +x ~/bin/kubens && \
    mkdir -p ~/.zsh/zsh-completions && \
    ln -sf ~/.kubectx/completion/kubectx.zsh /home/linuxbrew/.linuxbrew/share/zsh/site-functions/_kubectx && \
    ln -sf ~/.kubectx/completion/kubens.zsh /home/linuxbrew/.linuxbrew/share/zsh/site-functions/_kubens

COPY entrypoint.sh /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]
