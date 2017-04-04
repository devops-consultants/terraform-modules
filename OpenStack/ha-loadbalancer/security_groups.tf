resource "openstack_networking_secgroup_v2" "http" {
  name = "Loadbalancer HTTP Access"
  description = "Allow HTTP access to Load Balancer instances"
}

resource "openstack_networking_secgroup_rule_v2" "http_rule_1" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 80
  port_range_max = 80
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.http.id}"
}

resource "openstack_networking_secgroup_rule_v2" "http_rule_2" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 443
  port_range_max = 443
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.http.id}"
}
