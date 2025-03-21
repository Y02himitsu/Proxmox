#!/bin/bash
# Installation of jq, which is needed in the next step to extract information.
apt update
apt install jq -y

# Configuration variables for the cloud-init template.
NAME_TEMPLATE="ubuntu"
# cloud-init image URL and temporary download path.
CLOUD_INIT_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
DOWNLOAD_PATH="/tmp/cloud-init"
RESIZE_SIZE="10G" # This is for quick testing, you can change it to the desired size
CUSTOM_USER_NAME="demoproxmox" # This is the user that will be created by cloud-init
CUSTOM_USER_PASS="demoproxmox" # This is the password for the user that will be created by cloud-init

# Enable the snippet feature is needed to use the cloud-init configuration.
pvesm set local --content "images,iso,vztmpl,backup,rootdir,snippets"

# Retrieve a list of all used IDs - only locally in single-node Proxmox mode
used_ids=$(qm list | awk 'NR>1 {print $1}')
# Retrieve globally in the cluster
used_ids=$(pvesh get /cluster/resources --type vm --output-format json | jq -r '.[].vmid' | sort -nr | head -n1)

# Check if there are any VMs
if [ -z "$used_ids" ]; then
  new_id=9000  # If there are no VMs, start from 100
else
  # Check the free ID by getting the highest ID and adding +1
  new_id=$(echo "$used_ids" | sort -n | tail -n 1)
  new_id=$((new_id + 1))
fi

# Create the download path and download the cloud-init image
mkdir -p ${DOWNLOAD_PATH}
wget -O ${DOWNLOAD_PATH}/cloud-image.img ${CLOUD_INIT_IMAGE_URL}

# Resize the image to the desired size
echo "---> Resizing image to ${RESIZE_SIZE}"
qemu-img resize ${DOWNLOAD_PATH}/cloud-image.img ${RESIZE_SIZE}

# Create a new VM with the cloud-init image
echo "---> Creating new VM with ID: ${new_id}"
qm create ${new_id} --name "${NAME_TEMPLATE}-${new_id}-cloudinit" --ostype l26 --memory 1024 --agent=1,fstrim_cloned_disks=1 --bios ovmf --machine q35 --efidisk0 local-lvm:0,pre-enrolled-keys=0 --cpu host --socket 1 --cores 1 --net0 virtio,bridge=vmbr0,firewall=1

# Import the disk image
echo "---> Importing disk image"
qm importdisk ${new_id} ${DOWNLOAD_PATH}/cloud-image.img local-lvm

# Attach the disk image
echo "---> Attaching disk image"
qm set ${new_id} --scsihw virtio-scsi-pci --virtio0 local-lvm:vm-${new_id}-disk-1,discard=on

# Set the boot order
echo "---> Setting boot order"
qm set ${new_id} --boot order=virtio0

# Set the cloud-init drive
echo "---> Setting cloud-init"
qm set ${new_id} --ide2 local-lvm:cloudinit

# Set the cloud-init configuration
echo "---> Setting cloud-init configuration"
cat << EOF | tee /var/lib/vz/snippets/vendor.yaml
#cloud-config
runcmd:
    - apt update
    - apt install -y qemu-guest-agent
    - systemctl start qemu-guest-agent
    - reboot
EOF

# Set the cloud-init configuration
echo "---> Setting cloud-init configuration"
qm set ${new_id} --cicustom "vendor=local:snippets/vendor.yaml"
qm set ${new_id} --tags ${NAME_TEMPLATE},cloudinit
qm set ${new_id} --ciuser $CUSTOM_USER_NAME --ciupgrade 1
qm set ${new_id} --cipassword $(openssl passwd -6 $CUSTOM_USER_PASS)
qm set ${new_id} --sshkeys ~/.ssh/authorized_keys
qm set ${new_id} --ipconfig0 ip=dhcp

# Update the VM
echo "---> Cloud-init update VM"
qm cloudinit update ${new_id}

# Create a template
echo "---> VM ${new_id} created"
qm template ${new_id}

# Clean up
echo "---> Cleaning up"
rm ${DOWNLOAD_PATH}/cloud-image.img
