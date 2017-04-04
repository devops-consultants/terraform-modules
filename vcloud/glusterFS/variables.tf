variable "catalog"        { default = "DevOps" }
variable "vapp_template"  { default = "centos71" }

variable "domain_name"    { default = "example.com" }
variable "network_name"   { default = "Storage Network" }
variable "storage_vip"    { default = "192.168.1.100" }

variable "cpu_count"      { default = "2" }
variable "memory"         { default = "4096" }

variable "ssh_userid"     { default = "root" }
variable "ssh_user_home"  { default = "/root"}
variable "ssh_key_pub"    {}
variable "ssh_key_private" {}

variable "bastion_host"   { default = "" }
variable "bastion_userid" { default = "" }
variable "bastion_key_private" { default = "" }

variable "num_nodes"      { default = "2" }
variable "num_bricks"     { default = "1" }
variable "brick_size_mb"  { default = "10240" }
variable "gluster_vol"    { default = "data1" }

variable "vcd_org"        {}
variable "vcd_vdc"        {}
variable "vcd_userid"     {}
variable "vcd_pass"       {}
variable "vcd_api_url"    { default = "https://api.vcd.portal.skyscapecloud.com/api" }
