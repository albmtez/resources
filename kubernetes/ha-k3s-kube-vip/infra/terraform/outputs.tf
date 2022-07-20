# Ansible inventory file generation
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
  {
    k3s_servers_inventory = proxmox_vm_qemu.k3s_servers.*
    k3s_agents_inventory = proxmox_vm_qemu.k3s_agents.*
  })
  filename = "../common/inventory"
}
