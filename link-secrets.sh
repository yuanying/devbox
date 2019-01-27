#!/bin/bash

ROOT=$(dirname "${BASH_SOURCE}")
cd ${ROOT}
ROOT=$(pwd)

rm -f ~/.ssh/github_rsa
rm -f ~/.zsh_private

ln -s ${ROOT}/github_rsa ~/.ssh/github_rsa
chmod 0600 ~/.ssh/github_rsa
ln -s ${ROOT}/zsh_private ~/.zsh_private

