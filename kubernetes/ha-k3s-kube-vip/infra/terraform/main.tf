terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "-> 2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://${var.pm_host}:8006/api2/json"
  pm_tls_insecure = "true"
}

# Server nodes
resource "proxmox_vm_qemu" "k3s_servers" {
  count       = "${var.k3s_server_nodes.count}"
  vmid        = "${format("%03d", var.k3s_server_nodes.vmid + count.index)}"
  name        = "${var.k3s_server_nodes.name}-${count.index + 1}"
  target_node = "${var.target_node}"
  clone       = "${var.k3s_server_nodes.template}"
  full_clone  = false
  cores       = "${var.k3s_server_nodes.cores}"
  sockets     = 1
  memory      = "${var.k3s_server_nodes.memory}"
  bootdisk    = "virtio0"
  agent       = 1

  disk {
    size    = "${var.k3s_server_nodes.disk_size}"
    type    = "virtio"
    storage = "local-lvm"
  }

  lifecycle {
    ignore_changes = [
      network
    ]
  }

  # Cloud init settings
  ipconfig0  = "ip=${var.network.base_ip}${var.network.final_ip + count.index}/${var.network.net},gw=${var.network.gateway}"
  ciuser     = "${var.user.name}"
  cipassword = "${var.user.password}"
  sshkeys    = file("../common/ssh_key/id_rsa.pub")
}

# Agent nodes
resource "proxmox_vm_qemu" "k3s_agents" {
  count       = "${var.k3s_agent_nodes.count}"
  vmid        = "${format("%03d", var.k3s_agent_nodes.vmid + count.index)}"
  name        = "${var.k3s_agent_nodes.name}-${count.index + 1}"
  target_node = "${var.target_node}"
  clone       = "${var.k3s_agent_nodes.template}"
  full_clone  = false
  cores       = "${var.k3s_agent_nodes.cores}"
  sockets     = 1
  memory      = "${var.k3s_agent_nodes.memory}"
  bootdisk    = "virtio0"
  agent       = 1

  disk {
    size    = "${var.k3s_agent_nodes.disk_size}"
    type    = "virtio"
    storage = "local-lvm"
  }

  lifecycle {
    ignore_changes = [
      network
    ]
  }

  # Cloud init settings
  ipconfig0  = "ip=${var.network.base_ip}${var.network.final_ip + var.k3s_server_nodes.count + count.index}/${var.network.net},gw=${var.network.gateway}"
  ciuser     = "${var.user.name}"
  cipassword = "${var.user.password}"
  sshkeys    = file("../common/ssh_key/id_rsa.pub")
}

resource "time_sleep" "wait_for_vms_initialization" {
  depends_on = [proxmox_vm_qemu.k3s_servers, proxmox_vm_qemu.k3s_agents]

  create_duration = "120s"
}
