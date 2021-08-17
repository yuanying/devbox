#!/bin/bash
set -eu

ROOT=$(dirname "${BASH_SOURCE}")
source ${ROOT}/.env

docker network create -d macvlan \
    --subnet=172.18.1.1/16 \
    --gateway=172.18.1.1 \
    --subnet=2400:4050:b102:ab11::/64 \
    --gateway=2400:4050:b102:ab11::1 \
    --ipv6 \
     -o parent=br0 \
     -o macvlan_mode=bridge macvlan4to6
