# install vim plugins
FROM ubuntu:18.04 as vim_plugins_builder
RUN apt-get update && apt-get install -y git ca-certificates
RUN mkdir -p /root/.vim/plugged && cd /root/.vim/plugged && \
	git clone 'https://github.com/AndrewRadev/splitjoin.vim' && \
	git clone 'https://github.com/ConradIrwin/vim-bracketed-paste' && \
	git clone 'https://github.com/Raimondi/delimitMate' && \
	git clone 'https://github.com/SirVer/ultisnips' && \
	git clone 'https://github.com/cespare/vim-toml' && \
	git clone 'https://github.com/corylanou/vim-present' && \
	git clone 'https://github.com/ekalinin/Dockerfile.vim' && \
	git clone 'https://github.com/elzr/vim-json' && \
	git clone 'https://github.com/fatih/vim-go' && \
	git clone 'https://github.com/fatih/vim-hclfmt' && \
	git clone 'https://github.com/fatih/vim-nginx' && \
	git clone 'https://github.com/godlygeek/tabular' && \
	git clone 'https://github.com/hashivim/vim-hashicorp-tools' && \
	git clone 'https://github.com/junegunn/fzf.vim' && \
	git clone 'https://github.com/mileszs/ack.vim' && \
	git clone 'https://github.com/roxma/vim-tmux-clipboard' && \
	git clone 'https://github.com/plasticboy/vim-markdown' && \
	git clone 'https://github.com/scrooloose/nerdtree' && \
	git clone 'https://github.com/t9md/vim-choosewin' && \
	git clone 'https://github.com/tmux-plugins/vim-tmux' && \
	git clone 'https://github.com/tmux-plugins/vim-tmux-focus-events' && \
	git clone 'https://github.com/fatih/molokai' && \
	git clone 'https://github.com/tpope/vim-commentary' && \
	git clone 'https://github.com/tpope/vim-eunuch' && \
	git clone 'https://github.com/tpope/vim-fugitive' && \
	git clone 'https://github.com/tpope/vim-repeat' && \
	git clone 'https://github.com/tpope/vim-scriptease' && \
	git clone 'https://github.com/ervandew/supertab'

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
RUN set -x && brew install screen
RUN set -x && brew install jq
RUN set -x && brew install dep

FROM ubuntu:18.04

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
        wget

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
    useradd -G docker -m -s /bin/bash  -u 501 "$USER" && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER "$USER"
ENV HOME="/home/$USER"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
# linuxbrew
COPY --from=linuxbrew_installer /home/linuxbrew /home/linuxbrew

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

# zsh plugins
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

COPY entrypoint.sh /bin/entrypoint.sh
CMD ["/bin/entrypoint.sh"]
