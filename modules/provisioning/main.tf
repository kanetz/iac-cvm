terraform {
  required_providers {
    tencentcloud = {
      source = "tencentcloudstack/tencentcloud"
      version = "1.81.11"
    }
  }
}

variable "cpu_cores" {
  default = 4
}
variable "memory_GB" {
  default = 16
}
variable "instance_families" {
  default = ["S2"]
}
variable "os_name" {
  default = "CentOS 7.8 64bit"
}


locals {
  az_name       = data.tencentcloud_availability_zones_by_product.matched.zones[0].name
  instance_type = data.tencentcloud_instance_types.matched.instance_types[0].instance_type
  image_id      = data.tencentcloud_images.matched.images[0].image_id

  key_id = tencentcloud_key_pair.public_key.id
}


data "tencentcloud_availability_zones_by_product" "matched" {
  product = "cvm"
}
data "tencentcloud_instance_types" "matched" {
  cpu_core_count    = var.cpu_cores
  memory_size       = var.memory_GB
  exclude_sold_out  = true
  filter {
    name   = "zone"
    values = [local.az_name]
  }
  filter {
    name   = "instance-family"
    values = var.instance_families
  }
}
data "tencentcloud_images" "matched" {
  image_type = ["PUBLIC_IMAGE"]
  os_name    = var.os_name
}


resource "tls_private_key" "tls_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "local_sensitive_file" "private_key_file" {
  content  = tls_private_key.tls_key_pair.private_key_openssh
  filename = "${path.root}/cvm_${terraform.workspace}.key"
}
resource "tencentcloud_key_pair" "public_key" {
  key_name   = "KEY_CVM_${terraform.workspace}"

  public_key = tls_private_key.tls_key_pair.public_key_openssh
}

resource "tencentcloud_vpc" "vpc" {
  name       = "VPC_CVM_${terraform.workspace}"
  cidr_block = "10.0.0.0/16"
}
resource "tencentcloud_subnet" "subnet" {
  name              = "SUBNET_CVM_${terraform.workspace}"
  availability_zone = local.az_name
  vpc_id            = tencentcloud_vpc.vpc.id
  cidr_block        = "10.0.0.0/16"
}

resource "tencentcloud_security_group" "sec_grp" {
  name       = "SECGRP_CVM_${terraform.workspace}"
}
resource "tencentcloud_security_group_lite_rule" "sec_grp_rule" {
  security_group_id = tencentcloud_security_group.sec_grp.id

  ingress = [
    "ACCEPT#10.0.0.0/16#ALL#ALL",
    "ACCEPT#0.0.0.0/0#22#TCP",
  ]

  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL",
  ]
}

resource "tencentcloud_instance" "cvm_instance" {
  instance_name     = "CVM_${terraform.workspace}"
  vpc_id            = tencentcloud_vpc.vpc.id
  subnet_id         = tencentcloud_subnet.subnet.id
  availability_zone = local.az_name
  instance_type     = local.instance_type
  image_id          = local.image_id
  key_ids           = [local.key_id]

  allocate_public_ip         = true
  internet_max_bandwidth_out = 10
  orderly_security_groups    = [tencentcloud_security_group.sec_grp.id]

  system_disk_type  = "CLOUD_PREMIUM"
  system_disk_size  = 50

  data_disks {
    data_disk_type = "CLOUD_PREMIUM"
    data_disk_size = 50
    encrypt        = false
  }

  disable_monitor_service  = false
  disable_security_service = true

  connection {
    type        = "ssh"
    user        = "root"
    private_key = tls_private_key.tls_key_pair.private_key_openssh
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection is OK.'",
    ]
  }
}


output "cvm_instance" {
  value = tencentcloud_instance.cvm_instance
}
output "private_key_file" {
  value = local_sensitive_file.private_key_file
}
