output "addresses" {
	value = ["${vcd_vapp.gluster.*.ip}"]
}

output "storage_vip" {
	value = "${var.storage_vip}"
}