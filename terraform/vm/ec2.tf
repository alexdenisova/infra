# Official Debian images
data "aws_ami" "debian" {
  owners = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-13-amd64-20260316-2418"]
  }
}

locals {
  # Inbound TCP ports open to the internet
  vm_ingress_ports = {
    ssh          = 22
    http         = 80
    https        = 443
    microk8s-api = 16443
  }
}

# Subnet and key pair are left at what the instance already has
resource "aws_instance" "vm" {
  ami                    = data.aws_ami.debian.id
  instance_type          = "t3.xlarge"
  vpc_security_group_ids = [aws_security_group.vm.id]
  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }
  tags = {
    Name = "MicroK8s"
  }
  lifecycle {
    # Holds the microk8s cluster and its volumes
    prevent_destroy = true
  }
}

# Name and description come from the console launch wizard; changing them replaces the group
resource "aws_security_group" "vm" {
  name        = "launch-wizard-3"
  description = "launch-wizard-3 created 2026-10-30T20:45:25.614Z"
}

resource "aws_vpc_security_group_ingress_rule" "vm" {
  for_each          = local.vm_ingress_ports
  security_group_id = aws_security_group.vm.id
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "vm_all" {
  security_group_id = aws_security_group.vm.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# The public IP is auto-assigned and changes if the instance is stopped
output "vm_ip" {
  value = aws_instance.vm.public_ip
}
