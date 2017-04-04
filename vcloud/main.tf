variable "vcd_org"        {}
variable "vcd_vdc"        {}
variable "vcd_userid"     {}
variable "vcd_pass"       {}
#variable "chef_admin_password" { default = "secret" }
variable "vcd_api_url"    { default = "https://api.vcd.portal.skyscapecloud.com/api" }
variable "vcd_timeout"    { default = 300 }
variable "edge_gateway"   { default = "" }
variable "storage_net_cidr" { default = "10.200.0.1/24" }

# Configure the VMware vCloud Director Provider
provider "vcd" {
    user                 = "${var.vcd_userid}"
    org                  = "${var.vcd_org}"
    password             = "${var.vcd_pass}"
    vdc                  = "${var.vcd_vdc}"
    url                  = "${var.vcd_api_url}"
    allow_unverified_ssl = "false"
    maxRetryTimeout      = "${var.vcd_timeout}"
}

#module "chef_server" {
#	source          = "./ChefServer"
#
#    catalog         = "DevOps"
#    vapp_template   = "centos72"
#	network_name    = "Management Network"
#	int_ip          = "10.10.0.60"
#	hostname        = "chefserver.example.com"
#
#    ssh_userid      = "root"
#   ssh_user_home   = "/root"
#	ssh_key_pub     = "${file("~/.ssh/root.pub")}"
#	ssh_key_private = "${file("~/.ssh/root.private")}"
#
#    bastion_host        = "51.179.193.254"
#    bastion_userid      = "rcoward"
#    bastion_key_private = "${file("~/.ssh/root.private")}"
#
#	chef_admin_userid     = "admin" 
#	chef_admin_firstname  = "Admin" 
#	chef_admin_lastname   = "User" 
#	chef_admin_email      = "admin@example.com" 
#	chef_admin_password   = "${var.chef_admin_password}" 
#	chef_org_short        = "example" 
#	chef_org_full         = "Example Organisation" 
#}

resource "vcd_network" "storage_net" {
    name = "Demo Storage Network"
    edge_gateway = "${var.edge_gateway}"
    gateway = "${cidrhost(var.storage_net_cidr, 1)}"

    static_ip_pool {
        start_address = "${cidrhost(var.storage_net_cidr, 20)}"
        end_address = "${cidrhost(var.storage_net_cidr, 50)}"
    }

    dhcp_pool {
        start_address = "${cidrhost(var.storage_net_cidr, 100)}"
        end_address = "${cidrhost(var.storage_net_cidr, 200)}"
    }
}

module "gluster_cluster" {
    source = "./glusterFS"
    #depends_on = [ "vcd_network.storage_net" ]

    catalog         = "DevOps"
    vapp_template   = "centos72"
    network_name    = "${vcd_network.storage_net.name}"
    domain_name     = "devops-consultant.com"
    storage_vip     = "${cidrhost(var.storage_net_cidr, 10)}"

    num_nodes       = "2"

    ssh_userid      = "root"
    ssh_user_home   = "/root"
    ssh_key_pub     = "${file("~/.ssh/root.pub")}"
    ssh_key_private = "${file("~/.ssh/root.private")}"

    bastion_host        = "51.179.193.254"
    bastion_userid      = "rcoward"
    bastion_key_private = "${file("~/.ssh/root.private")}"

    vcd_userid          = "${var.vcd_userid}"
    vcd_org             = "${var.vcd_org}"
    vcd_pass            = "${var.vcd_pass}"
    vcd_vdc             = "${var.vcd_vdc}"
    vcd_api_url         = "${var.vcd_api_url}"
}