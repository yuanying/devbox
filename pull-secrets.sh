#!/bin/bash

set -eu

ROOT=$(dirname "${BASH_SOURCE}")
cd ${ROOT}
ROOT=$(pwd)

echo "Authenticating with 1Password"
export OP_SESSION_my=$(op signin https://my.1password.com yuanying@fraction.jp --output=raw)

echo "Pulling secrets"
# private keys
op get document 'github_rsa' > github_rsa
op get document 'zsh_private' > zsh_private

rm -f ~/.ssh/github_rsa
rm -f ~/.zsh_private

ln -s ${ROOT}/github_rsa ~/.ssh/github_rsa
chmod 0600 ~/.ssh/github_rsa
ln -s ${ROOT}/zsh_private ~/.zsh_private

popd

echo "Done!"
