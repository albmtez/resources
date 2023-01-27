#!/bin/bash

multipass delete k3s-server-node-1
multipass delete k3s-server-node-2
multipass delete k3s-server-node-3
multipass delete k3s-agent-node-1
multipass delete k3s-agent-node-2
multipass delete k3s-agent-node-3

multipass purge
