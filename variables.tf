variable "vcd_org"        {}
variable "vcd_userid"     {}
variable "vcd_pass"       {}
variable "catalog"        { default = "DevOps" }
variable "vapp_template"  { default = "centos71" }
variable "edge_gateway"   { default = "Edge Gateway Name" }
variable "jumpbox_ext_ip" { default = "51.179.193.253" }
variable "jumpbox_int_ip" { default = "10.10.0.100" }
variable "ssh_userid"     { default = "root" }
variable "ssh_user_home"  { default = "/root"}
variable "chef_admin_password" {}
