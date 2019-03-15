#!/bin/bash

set -e

mkdir -p ~/.ssh
curl -fsL https://github.com/yuanying.keys > ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

export EDITOR=vim
export GOPATH="$HOME"
export GHQ_ROOT="$HOME/src"

mkdir -p ~/secrets
cp ~/bin/*-secrets.sh ~/secrets/
bash ~/secrets/link-secrets.sh

git clone https://github.com/yuanying/dotfiles ~/dotfiles
bash dotfiles/bin/setup.sh

sudo /usr/sbin/sshd -D
