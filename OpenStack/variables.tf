variable "vcd_org"        {}
variable "vcd_userid"     {}
variable "vcd_pass"       {}
variable "vcd_api_url"    { default = "https://api.vcd.portal.skyscapecloud.com/api" }
variable "vcd_timeout"    { default = 300 }

variable "catalog"        { default = "DevOps" }
variable "vapp_template"  { default = "centos71" }

variable "edge_gateway"      { default = "Edge Gateway Name" }
variable "internal_net_cidr" { default = "192.168.150.0/24" }
variable "vm_net_cidr"       { default = "192.168.151.0/24" }
variable "public_net_cidr"   { default = "192.168.152.0/24" }

variable "ext_ip"         { default = "10.20.30.40" }

variable "ceph_mon_instances" { default = "1" }
variable "ceph_osd_instances" { default = "2" }

variable "ssh_userid"     { default = "root" }
variable "ssh_user_home"  { default = "/root"}
variable "ssh_key_pub"    {}
variable "ssh_key_private" {}

variable "bastion_host"   {}
variable "bastion_userid" { default = "root" }
variable "bastion_key_private" {}
