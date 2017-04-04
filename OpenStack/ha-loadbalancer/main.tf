
data "template_file" "loadbalancer_config" {
  template = "${file("files/init.tpl")}"
  count = "${var.num_instances}"

  vars {
    hostname = "${format("%s%02d", var.hostname_prefix, count.index + 1)}"
    fqdn     = "${format("%s%02d", var.hostname_prefix, count.index + 1)}.${var.domain_name}"
  }
}

resource "openstack_compute_servergroup_v2" "loadbalancer" {
  name = "loadbalancer-servergroup"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "loadbalancer" {
  name        = "${format("%s%02d", var.hostname_prefix, count.index + 1)}.${var.domain_name}"
  image_name  = "${var.image}"
  flavor_name = "${var.type}"
  key_pair    = "${var.ssh_keypair}"
  security_groups = ["${var.security_group_local_access}",
                     "${openstack_networking_secgroup_v2.http.name}"]
  availability_zone = "${element(var.availability_zones, count.index)}"
  scheduler_hints = { group = "${openstack_compute_servergroup_v2.loadbalancer.id}" }

  user_data = "${element(data.template_file.loadbalancer_config.*.rendered, count.index)}"

  count = "${var.num_instances}"

  network {
    name = "${var.lb_network}"
  }

  connection {
    bastion_host = "${openstack_compute_floatingip_v2.infra_host_ip.address}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_file)}"

    user = "centos"
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp ~centos/.ssh/authorized_keys /root/.ssh",
      "sudo chmod -R go-rwx /root/.ssh",
      "sudo yum install -y NetworkManager epel-release",
      "sudo systemctl enable NetworkManager.service",
      "sudo systemctl start NetworkManager.service"
    ]
  }
  
}
