 
# Configure the VMware vCloud Director Provider
provider "vcd" {
    user            = "${var.vcd_userid}"
    org             = "${var.vcd_org}"
    password        = "${var.vcd_pass}"
    url             = "https://api.vcd.portal.skyscapecloud.com/api"
    maxRetryTimeout = 300
}

resource "tls_private_key" "devops-consultant" {
    algorithm = "RSA"
    rsa_bits = "4096"
}

resource "tls_self_signed_cert" "devops-consultant" {
    key_algorithm = "${tls_private_key.devops-consultant.algorithm}"
    private_key_pem = "${tls_private_key.devops-consultant.private_key_pem}"

    # Certificate expires after 12 hours.
    validity_period_hours = 12

    # Generate a new certificate if Terraform is run within three
    # hours of the certificate's expiration time.
    early_renewal_hours = 3

    # Reasonable set of uses for a server SSL certificate.
    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth",
    ]

    dns_names = ["chef01.demo.devops-consultant.com", "compliance.demo.devops-consultant.com"]

    subject {
        common_name = "devops-consultant.com"
        organization = "DevOps Consultancy"
    }
}

resource "vcd_vapp" "jumpbox" {
    name          = "devopsjump01"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = 512
    cpus          = 1
    network_name  = "Management Network"
    ip            = "${var.jumpbox_int_ip}"
    initscript    = "mkdir -p ${var.ssh_user_home}/.ssh; echo \"${file("~/.ssh/${var.ssh_userid}.pub")}\" >> ${var.ssh_user_home}/.ssh/authorized_keys; chmod -R go-rwx ${var.ssh_user_home}/.ssh; restorecon -Rv ${var.ssh_user_home}/.ssh"

}

resource "null_resource" "jumpbox" {

	connection {
    	host = "${vcd_dnat.jumpbox-ssh.external_ip}"
    	user = "${var.ssh_userid}"
    	private_key = "${file("~/.ssh/${var.ssh_userid}.private")}"
    }

    provisioner "remote-exec" {
        inline = [
        "userdel vagrant",
        "yum -y install haproxy",
        "mkdir -p /etc/haproxy/certs",
        "echo '${tls_self_signed_cert.devops-consultant.cert_pem}' > /etc/haproxy/certs/proxy.pem",
        "echo '${tls_private_key.devops-consultant.private_key_pem}' >> /etc/haproxy/certs/proxy.pem",
        "mkdir -p ~/.ssh",
        "echo '${file("~/.ssh/${var.ssh_userid}.private")}' > ~/.ssh/id_rsa",
        "chmod 600 ~/.ssh/id_rsa"
        ]
    }
}

# Inbound SSH to the Jumpbox server
resource "vcd_dnat" "jumpbox-ssh" {

    edge_gateway  = "${var.edge_gateway}"
    external_ip   = "${var.jumpbox_ext_ip}"
    port          = 22
    internal_ip   = "${vcd_vapp.jumpbox.ip}"
}

resource "vcd_firewall_rules" "jumpbox-fw" {
    edge_gateway   = "${var.edge_gateway}"
    default_action = "drop"

    rule {
        description      = "allow-jumpbox-ssh"
        policy           = "allow"
        protocol         = "tcp"
        destination_port = "22"
        destination_ip   = "${var.jumpbox_ext_ip}"
        source_port      = "any"
        source_ip        = "any"
    }
}

#module "powerdns" {
#	source = "./PowerDNSServer"
#
#	vcd_org    = "${var.vcd_org}"
#	vcd_userid = "${var.vcd_userid}"
#	vcd_pass   = "${var.vcd_pass}"
#
#	edge_gateway = "${var.edge_gateway}"
#
#	ssh_key_pub     = "${file("~/.ssh/${var.ssh_userid}.pub")}"
#	ssh_key_private = "${file("~/.ssh/${var.ssh_userid}.private")}"
#
#	bastion_host        = "${vcd_dnat.jumpbox-ssh.external_ip}"
#	bastion_key_private = "${file("~/.ssh/${var.ssh_userid}.private")}"
#}

module "chef_server" {
	source     = "./ChefServer"

	vcd_org    = "${var.vcd_org}"
	vcd_userid = "${var.vcd_userid}"
	vcd_pass   = "${var.vcd_pass}"

	edge_gateway = "${var.edge_gateway}"
	ext_ip       = "${vcd_dnat.jumpbox-ssh.external_ip}"
	network_name = "Management Network"
	int_ip       = "10.10.0.50"

	ssh_key_pub     = "${file("~/.ssh/${var.ssh_userid}.pub")}"
	ssh_key_private = "${file("~/.ssh/${var.ssh_userid}.private")}"

	bastion_host        = "${vcd_dnat.jumpbox-ssh.external_ip}"
	bastion_key_private = "${file("~/.ssh/${var.ssh_userid}.private")}"

	chef_admin_userid     = "rcoward" 
	chef_admin_firstname  = "Rob" 
	chef_admin_lastname   = "Coward" 
	chef_admin_email      = "rcoward@skyscapecloud.com" 
	chef_admin_password   = "${var.chef_admin_password}" 
	chef_org_short        = "skyscape" 
	chef_org_full         = "Skyscape Cloud Services" 
}

module "compliance_server" {
    source     = "./ChefCompliance"

    vcd_org    = "${var.vcd_org}"
    vcd_userid = "${var.vcd_userid}"
    vcd_pass   = "${var.vcd_pass}"
    hostname   = "compliance.demo.devops-consultant.com"

    edge_gateway = "${var.edge_gateway}"
    ext_ip       = "${vcd_dnat.jumpbox-ssh.external_ip}"
    network_name = "Management Network"
    int_ip       = "10.10.0.51"

    ssh_key_pub     = "${file("~/.ssh/${var.ssh_userid}.pub")}"
    ssh_key_private = "${file("~/.ssh/${var.ssh_userid}.private")}"

    bastion_host        = "${vcd_dnat.jumpbox-ssh.external_ip}"
    bastion_key_private = "${file("~/.ssh/${var.ssh_userid}.private")}"
}
