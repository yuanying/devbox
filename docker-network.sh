#!/bin/bash
set -eu

ROOT=$(dirname "${BASH_SOURCE}")
source ${ROOT}/.env

docker network create -d macvlan \
    --subnet=${SUBNET_IPV4} \
    --gateway=${GATEWAY_IPV4} \
    --subnet=${SUBNET_IPV6} \
    --gateway=${GATEWAY_IPV6} \
    --ipv6 \
     -o parent=${INTERFACE} \
     -o macvlan_mode=bridge macvlan4to6
