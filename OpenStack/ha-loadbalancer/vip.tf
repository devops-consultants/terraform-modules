resource "openstack_compute_floatingip_v2" "loadbalancer_ip" {
  pool = "${var.OS_INTERNET_NAME}"
}

resource "openstack_networking_port_v2" "port_1" {
  name           = "port_1"
  network_id     = "${var.lb_network}"
  admin_state_up = "true"
}