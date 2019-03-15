#!/bin/bash

ROOT=$(dirname "${BASH_SOURCE}")
cd ${ROOT}
ROOT=$(pwd)

if [[ -f ${ROOT}/id_rsa ]]; then
    rm -f ~/.ssh/id_rsa
    ln -s ${ROOT}/id_rsa ~/.ssh/id_rsa
    chmod 0600 ~/.ssh/id_rsa
fi
if [[ -f ${ROOT}/github_rsa ]]; then
    rm -f ~/.ssh/github_rsa
    ln -s ${ROOT}/github_rsa ~/.ssh/github_rsa
    chmod 0600 ~/.ssh/gihub_rsa
fi
if [[ -f ${ROOT}/zsh_private ]]; then
  rm -f ~/.zsh_private
  ln -s ${ROOT}/zsh_private ~/.zsh_private
fi

