#!/bin/bash

multipass delete k3s-server-node-1
multipass delete k3s-server-node-2
multipass delete k3s-server-node-3
multipass delete k3s-agent-node-1
multipass delete k3s-agent-node-2
multipass delete k3s-agent-node-3

multipass purge

multipass launch -n k3s-server-node-1 -c 2 -m 2G -d 30G --cloud-init cloud.init
multipass launch -n k3s-server-node-2 -c 2 -m 2G -d 30G --cloud-init cloud.init
multipass launch -n k3s-server-node-3 -c 2 -m 2G -d 30G --cloud-init cloud.init
multipass launch -n k3s-agent-node-1 -c 2 -m 2G -d 30G --cloud-init cloud.init
multipass launch -n k3s-agent-node-2 -c 2 -m 2G -d 30G --cloud-init cloud.init
multipass launch -n k3s-agent-node-3 -c 2 -m 2G -d 30G --cloud-init cloud.init

echo "[k3s_servers]" > ../common/inventory
multipass list | grep k3s | awk {' print $1" ansible_host="$3 '} | grep server >> ../common/inventory
echo "[k3s_agents]" >> ../common/inventory
multipass list | grep k3s | awk {' print $1" ansible_host="$3 '} | grep agent >> ../common/inventory

