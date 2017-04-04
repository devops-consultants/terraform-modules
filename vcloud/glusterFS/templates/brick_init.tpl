#!/usr/bin/bash
#
VM_NAME=$${1:-$(hostname)}
VCLOUD_ORG=$2
VCLOUD_USERNAME=$3
VCLOUD_PASSWORD=$4
export VCLOUD_ORG VCLOUD_USERNAME VCLOUD_PASSWORD

NUM_BRICKS=$${5:-${num_bricks}}
BRICK_SIZE=$${6:-${brick_size_Mb}}

# First step is to ensure the additional disks for this VM have been provisioned.
# This is a temporary work around until Terraform is able to provision additional
# disks when launching a VM.
ruby /tmp/additional_disks.rb $VM_NAME $NUM_BRICKS $BRICK_SIZE

# Force a rescan of the SCSI bus incase the new disks were not automatically picked up.
echo "- - -" > /sys/class/scsi_host/host0/scan

# For each disk device other than /dev/sda, ensure a partition, filesystem and
# mount point is created.
BRICK_NUM=1
for disk_dev in $(ls /dev/sd[b-z])
do
	MOUNT_PATH=${mount_path}/brick-$BRICK_NUM
	BRICK_DEV="$${disk_dev}1"

	if [ ! -b $BRICK_DEV ];
	then
		echo "o
n
p
1


w
"|fdisk $disk_dev
		mkfs.xfs $BRICK_DEV
	fi
	[[ -d $MOUNT_PATH ]] || mkdir -p $MOUNT_PATH
	[[ $(grep -c $MOUNT_PATH /etc/fstab) -gt 0 ]] || echo "$BRICK_DEV $MOUNT_PATH xfs defaults 0 0" >> /etc/fstab
	mount $MOUNT_PATH
	[[ -d $MOUNT_PATH/${data_volume} ]] || mkdir -p $MOUNT_PATH/${data_volume}
	BRICK_NUM=`expr $BRICK_NUM + 1`
done

# Add hosts file entries for all the gluster nodes
cat <<-EOF | awk '{split($2,a,"."); print $1,a[1],$2}' >>/etc/hosts
${hosts}
EOF