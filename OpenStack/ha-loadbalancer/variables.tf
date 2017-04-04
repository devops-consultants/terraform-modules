variable "image" { default = "CentOS 7" }
variable "type" { default = "t1.small" }
variable "num_instances" { default = "2" }
variable "security_group_local_access" { default = "interal-ssh" }

variable "user" { default = "centos" }
variable "public_key_file" { default = "~/.ssh/user.pub" }
variable "private_key_file" { default = "~/.ssh/user.private" }
variable "ssh_keypair" { default = "MyKey" }

variable "bastion_host" {}
variable "bastion_user" { default = "centos" }
variable "bastion_private_key" { default = "~/.ssh/user.private" }

variable "availability_zones" { default = ["0000c-1", "0000c-2"] }
variable "OS_INTERNET_NAME" { default = "internet" }

variable "lb_network" { default = "dmz_network" }
variable "domain_name" { default = "example.com" }
variable "hostname_prefix" { default = "lb" }


