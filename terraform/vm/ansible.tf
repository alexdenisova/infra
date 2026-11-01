locals {
  vm_group_name = "vm"
}

resource "ansible_group" "all" {
  inventory_group_name = "all"
  vars = { for k, v in merge(
    {
      ansible_ssh_private_key_file = "{{ playbook_dir }}/files/generated.id_rsa"
      ansible_ssh_private_key      = data.sops_file.main.data["ansible_ssh_private_key"]
    },
  ) : k => yamlencode(v) }
}

resource "ansible_host" "aws_vm" {
  inventory_hostname = aws_instance.vm.public_ip
  groups             = [local.vm_group_name]
  vars = {
    for k, v in {
      ansible_user    = "admin"
      microk8s__users = ["admin"]
    } : k => yamlencode(v)
  }
}

resource "ansible_group" "bootstrap" {
  inventory_group_name = local.vm_group_name
  vars = {
    for k, v in {
      bootstrap__allow_tcp_ports = [16443, 19001]
    } : k => yamlencode(v)
  }
}
