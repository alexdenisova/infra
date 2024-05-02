resource "ansible_host" "yandex_vm" {
  inventory_hostname = "62.84.119.96"
  groups             = [local.vm_group_name]
  vars = {
    for k, v in {
      ansible_user                 = "alexdenisova"
      ansible_ssh_private_key_file = "~/.ssh/id_rsa"
    } : k => yamlencode(v)
  }
}

resource "ansible_group" "bootstrap" {
  inventory_group_name = local.vm_group_name
  vars = {
    for k, v in {
      bootstrap__allow_tcp_ports = [16443]
    } : k => yamlencode(v)
  }
}
