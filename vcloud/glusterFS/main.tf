# Create a vApp for the Chef Server
resource "vcd_vapp" "gluster" {
    name        = "${format("gluster%02d", count.index + 1)}.${var.domain_name}"
    catalog_name  = "${var.catalog}"
    template_name = "${var.vapp_template}"
    memory        = "${var.memory}"
    cpus          = "${var.cpu_count}"
    network_name  = "${var.network_name}"

    count         = "${var.num_nodes}"

    initscript    = "mkdir -p ${var.ssh_user_home}/.ssh; echo \"${var.ssh_key_pub}\" >> ${var.ssh_user_home}/.ssh/authorized_keys; chmod -R go-rwx ${var.ssh_user_home}/.ssh; restorecon -Rv ${var.ssh_user_home}/.ssh"
}

data "template_file" "brick_init" {
  template = "${file("${path.module}/templates/brick_init.tpl")}"
  vars {
    mount_path    = "/gluster/bricks/"
    data_volume   = "${var.gluster_vol}"
    num_bricks    = "${var.num_bricks}"
    brick_size_Mb = "${var.brick_size_mb}"
    hosts         = "${join("\n", formatlist("%s %s", vcd_vapp.gluster.*.ip, vcd_vapp.gluster.*.name ))}"
  }
}

data "template_file" "additional_disks" {
  template = "${file("${path.module}/templates/additional_disks.rb")}"
  vars {
    vcd_api_url    = "${var.vcd_api_url}"
  }
}

resource "null_resource" "gluster" {
    depends_on = [ "vcd_vapp.gluster" ]

    # Changes to any instance of the cluster requires re-provisioning
    triggers {
        instance_id = "${element(vcd_vapp.gluster.*.ip, count.index)}"
        num_bricks  = "${var.num_bricks}"
    }
    count         = "${var.num_nodes}"

    connection {
        host        = "${element(vcd_vapp.gluster.*.ip, count.index)}"
        user        = "${var.ssh_userid}"
        private_key = "${var.ssh_key_private}"

        bastion_host        = "${var.bastion_host}"
        bastion_user        = "${var.bastion_userid}"
        bastion_private_key = "${var.bastion_key_private}"
    }

    provisioner "remote-exec" {
        inline = [
            "yum install -y centos-release-gluster",
            "yum update -y --exclude=kernel",
            "yum install -y glusterfs-server",
            "systemctl enable glusterd.service",
            "systemctl start glusterd.service"
        ]
    }

    provisioner "file" {
        content = "${data.template_file.brick_init.rendered}"
        destination = "/tmp/create_bricks"
    }

    provisioner "file" {
        content = "${data.template_file.additional_disks.rendered}"
        destination = "/tmp/additional_disks.rb"
    }


    provisioner "remote-exec" {
        inline = [
            "yum -y install ruby ruby-devel",
            "yum -y groupinstall 'Development Tools'",
            "gem install rest-client",
            "gem install xml-simple",
            "sh /tmp/create_bricks ${element(vcd_vapp.gluster.*.name, count.index)} ${var.vcd_org} ${var.vcd_userid} '${var.vcd_pass}'"
        ]
    }
}

# Node 1 to probe all the other nodes to setup the trusted pool
resource "null_resource" "trusts_step_1" {
    depends_on = [ "null_resource.gluster" ]

    # Changes to any instance of the cluster requires re-provisioning
    triggers {
        instance_id = "${element(vcd_vapp.gluster.*.ip, count.index)}"
        num_nodes  = "${var.num_nodes}"
    }

    connection {
        host        = "${element(vcd_vapp.gluster.*.ip, 0)}"
        user        = "${var.ssh_userid}"
        private_key = "${var.ssh_key_private}"

        bastion_host        = "${var.bastion_host}"
        bastion_user        = "${var.bastion_userid}"
        bastion_private_key = "${var.bastion_key_private}"
    }

    provisioner "remote-exec" {
        inline = [
            "${join(";\n", formatlist("[[ '%s' == $(hostname) ]] || gluster peer probe %s", vcd_vapp.gluster.*.name, vcd_vapp.gluster.*.name))}",
        ]
    }
}

# Node 2 to probe peer 1 to complete the trusted pool
resource "null_resource" "trusts_step_2" {
    depends_on = [ "null_resource.trusts_step_1" ]

    # Changes to any instance of the cluster requires re-provisioning
    triggers {
        instance_id = "${element(vcd_vapp.gluster.*.ip, count.index)}"
        num_nodes  = "${var.num_nodes}"
    }

    connection {
        host        = "${element(vcd_vapp.gluster.*.ip, 1)}"
        user        = "${var.ssh_userid}"
        private_key = "${var.ssh_key_private}"

        bastion_host        = "${var.bastion_host}"
        bastion_user        = "${var.bastion_userid}"
        bastion_private_key = "${var.bastion_key_private}"
    }

    provisioner "remote-exec" {
        inline = [
            "gluster peer probe ${element(vcd_vapp.gluster.*.name, 0)}"
        ]
    }
}

# Node 1 to probe all the other nodes to setup the trusted pool
resource "null_resource" "create_volume" {
    depends_on = [ "null_resource.trusts_step_2" ]

    # Changes to any instance of the cluster requires re-provisioning
    triggers {
        instance_id = "${element(vcd_vapp.gluster.*.ip, count.index)}"
        num_nodes  = "${var.num_nodes}"
    }

    connection {
        host        = "${element(vcd_vapp.gluster.*.ip, 0)}"
        user        = "${var.ssh_userid}"
        private_key = "${var.ssh_key_private}"

        bastion_host        = "${var.bastion_host}"
        bastion_user        = "${var.bastion_userid}"
        bastion_private_key = "${var.bastion_key_private}"
    }

    provisioner "remote-exec" {
        inline = [
            "gluster volume create ${var.gluster_vol} replica 2  ${join(" ", formatlist("%s:/gluster/bricks/brick-1/%s", vcd_vapp.gluster.*.name, var.gluster_vol))}",
            "gluster volume start  ${var.gluster_vol}",
            "gluster volume info"
        ]
    }
}
