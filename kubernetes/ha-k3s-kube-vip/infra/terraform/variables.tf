variable "pm_host" {
  type = string
  default = "mortadelo"
  description = "Proxmox hostname"
}

variable "target_node" {
  type        = string
  default     = "filemon"
  description = "Proxmox target node"
}

variable "user" {
  type = map
  default = {
    "name"     = "kube"
    "password" = "pirate"
  }
  description = "System user"
}

variable "network" {
  type = map
  default = {
    "base_ip"    = "192.168.10."
    "final_ip"   = "51"
    "virtual_ip" = "50"
    "net"        = "24"
    "gateway"    = "192.168.10.1"
  }
  description = "Network configuration"
}

variable "k3s_server_nodes" {
  type = map
  default = {
    "count"     = 3
    "vmid"      = 401
    "name"      = "k3s-server-node"
    "template"  = "template-debian-11"
    "cores"     = 2
    "memory"    = 4096
    "disk_size" = "20G"
  }
  description = "Server nodes settings"
}

variable "k3s_agent_nodes" {
  type = map
  default = {
    "count"     = 3
    "vmid"      = 404
    "name"      = "k3s-agent-node"
    "template"  = "template-debian-11"
    "cores"     = 2
    "memory"    = 4096
    "disk_size" = "50G"
  }
  description = "Agent nodes settings"
}

