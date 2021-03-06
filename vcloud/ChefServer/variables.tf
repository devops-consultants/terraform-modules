variable "catalog"        { default = "DevOps" }
variable "vapp_template"  { default = "centos71" }

variable "hostname"       { default = "chef01" }
variable "network_name"   { default = "Management Network" }
variable "cpu_count"      { default = "2" }
variable "memory"         { default = "4096" }

variable "edge_gateway"   { default = "Edge Gateway Name" }
variable "int_ip"         { default = "192.168.100.100" }
variable "ext_ip"         { default = "10.20.30.40" }

variable "ssh_userid"     { default = "root" }
variable "ssh_user_home"  { default = "/root"}
variable "ssh_key_pub"    {}
variable "ssh_key_private" {}

variable "bastion_host"   { default = "" }
variable "bastion_userid" { default = "" }
variable "bastion_key_private" { default = "" }

variable "chef_download"  { default = "https://packages.chef.io/stable/el/7/chef-server-core-12.5.0-1.el7.x86_64.rpm" }
variable "chef_admin_userid"    { default = "administrator" }
variable "chef_admin_firstname" { default = "System" }
variable "chef_admin_lastname"  { default = "Administrator" }
variable "chef_admin_email"     { default = "admin@example.com" }
variable "chef_admin_password"  { default = "secret" }
variable "chef_org_short"       { default = "example" }
variable "chef_org_full"        { default = "Example Organisation" }