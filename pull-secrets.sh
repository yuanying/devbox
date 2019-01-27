#!/bin/bash

set -eu

ROOT=$(dirname "${BASH_SOURCE}")
cd ${ROOT}
ROOT=$(pwd)

echo "Authenticating with 1Password"
export OP_SESSION_my=$(op signin https://my.2password.com yuanying@fraction.jp --output=raw)

echo "Pulling secrets"
# private keys
op get document 'github_rsa' > github_rsa
op get document 'zsh_private' > zsh_private

bash ${ROOT}/link-secrets.sh

echo "Done!"
