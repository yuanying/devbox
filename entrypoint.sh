#!/bin/bash

#set -e

echo "Setup ssh"
mkdir -p ~/.ssh
curl -fsL https://github.com/yuanying.keys > ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

echo "Setup env"
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

export EDITOR=vim
export GOPATH="$HOME"
export GHQ_ROOT="$HOME/src"

echo "Setup secrets"
mkdir -p ~/secrets
cp ~/bin/*-secrets.sh ~/secrets/
bash ~/secrets/link-secrets.sh

echo "Clone dotfiles and setup"
git clone https://github.com/yuanying/dotfiles ~/dotfiles
bash dotfiles/bin/setup.sh
echo "Installing vim plugins..."
vim -E -s -u "~/.vimrc" +PlugInstall +qall

echo "Starting sshd..."
sudo /usr/sbin/sshd -D
