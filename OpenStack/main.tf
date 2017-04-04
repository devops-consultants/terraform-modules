# Configure the VMware vCloud Director Provider
provider "vcd" {
    user            = "${var.vcd_userid}"
    org             = "${var.vcd_org}"
    password        = "${var.vcd_pass}"
    url             = "${var.vcd_api_url}"
    maxRetryTimeout = "${var.vcd_timeout}"
}

# Create our networks
resource "vcd_network" "internal_net" {
    name = "OpenStack Internal Network"
    edge_gateway = "${var.edge_gateway}"
    gateway = "${cidrhost(var.internal_net_cidr, 1)}"

    static_ip_pool {
        start_address = "${cidrhost(var.internal_net_cidr, 10)}"
        end_address = "${cidrhost(var.internal_net_cidr, 200)}"
    }
}

resource "vcd_network" "vm_net" {
    name = "OpenStack VM Network"
    edge_gateway = "${var.edge_gateway}"
    gateway = "${cidrhost(var.vm_net_cidr, 1)}"

    static_ip_pool {
        start_address = "${cidrhost(var.vm_net_cidr, 10)}"
        end_address = "${cidrhost(var.vm_net_cidr, 200)}"
    }
}

resource "vcd_network" "public_net" {
    name = "OpenStack Public Network"
    edge_gateway = "${var.edge_gateway}"
    gateway = "${cidrhost(var.public_net_cidr, 1)}"

    static_ip_pool {
        start_address = "${cidrhost(var.public_net_cidr, 10)}"
        end_address = "${cidrhost(var.public_net_cidr, 200)}"
    }
}

# SNAT Outbound traffic
resource "vcd_snat" "internal_net-outbound" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.ext_ip}"
    internal_ip   = "${var.internal_net_cidr}"
}

resource "vcd_snat" "vm_net-outbound" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.ext_ip}"
    internal_ip   = "${var.vm_net_cidr}"
}

resource "vcd_snat" "public_net-outbound" {
    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.ext_ip}"
    internal_ip   = "${var.public_net_cidr}"
}


# Ceph Storage Cluster
# Webserver VMs on the Webserver network
resource "vcd_vapp" "ceph_mon" {
    name          = "${format("cephmon%02d", count.index + 1)}"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = 1024
    cpus          = 1
    network_name  = "${vcd_network.internal_net.name}"
    ip            = "${cidrhost(var.internal_net_cidr, count.index + 20)}"
    initscript    = "mkdir -p ${var.ssh_user_home}/.ssh; echo \"${var.ssh_key_pub}\" >> ${var.ssh_user_home}/.ssh/authorized_keys; chmod -R go-rwx ${var.ssh_user_home}/.ssh; restorecon -Rv ${var.ssh_user_home}/.ssh"


    count         = "${var.ceph_mon_instances}"
}

resource "vcd_vapp" "ceph_osd" {
    name          = "${format("cephosd%02d", count.index + 1)}"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = 1024
    cpus          = 1
    network_name  = "${vcd_network.internal_net.name}"
    ip            = "${cidrhost(var.internal_net_cidr, count.index + 30)}"
    initscript    = "mkdir -p ${var.ssh_user_home}/.ssh; echo \"${var.ssh_key_pub}\" >> ${var.ssh_user_home}/.ssh/authorized_keys; chmod -R go-rwx ${var.ssh_user_home}/.ssh; restorecon -Rv ${var.ssh_user_home}/.ssh"

    count         = "${var.ceph_osd_instances}"
}


resource "vcd_firewall_rules" "openstack" {
    edge_gateway   = "${var.edge_gateway}"
    default_action = "drop"

    rule {
        description      = "allow-int-outbound"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "any"
        source_port      = "any"
        source_ip        = "${var.internal_net_cidr}"
    }

        rule {
        description      = "allow-vm-outbound"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "any"
        source_port      = "any"
        source_ip        = "${var.vm_net_cidr}"
    }

    rule {
        description      = "allow-pub-outbound"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "any"
        source_port      = "any"
        source_ip        = "${var.public_net_cidr}"
    }
}
