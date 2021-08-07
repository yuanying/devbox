#!/usr/bin/env bash

set -e

contid=devbox
subnet=fde0:17ad:84c5:82::/64
pid=$(docker inspect -f '{{ .State.Pid }}' $contid)
netns=/proc/$pid/ns/net

export CNI_PATH=/opt/cni/bin
export CNI_COMMAND=ADD
export PATH=$CNI_PATH:$PATH
export CNI_CONTAINERID=$contid
export CNI_NETNS=$netns
export CNI_IFNAME=eth1

/opt/cni/bin/bridge <<EOF
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "dev01",
    "isDefaultGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${subnet}"}]
        ]
    }
}
EOF
