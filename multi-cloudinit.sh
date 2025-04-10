#!/usr/bin/env bash

# Copyright (c) 2021-2025 Help Point IT
# Author: Piotr Kośka (piotr.koska) therealmamuth github
# License:

# Global variables
declare -A CLOUD_IMAGES_DISTROS=(
    ["Alma Linux 9"]="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
    ["Alma Linux 8"]="https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2"
    ["CentOS Stream"]="https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
    ["Ubuntu 24.04 LTS"]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    ["Ubuntu 22.04 LTS"]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    ["Ubuntu 20.04 LTS"]="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
    ["OpenSUSE Leap 15.6"]="https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.6/images/openSUSE-Leap-15.6.x86_64-NoCloud.qcow2"
    ["OpenSUSE Leap 15.5"]="https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.5/images/openSUSE-Leap-15.5.x86_64-NoCloud.qcow2"
    ["OpenSUSE Leap 15.4"]="https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.4/images/openSUSE-Leap-15.4.x86_64-NoCloud.qcow2"
    ["Fedora 40 Server"]="https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
    ["Debian 12 (Bookworm)"]="https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
    ["Debian 11 (Bullseye)"]="https://cdimage.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
    ["Debian 10 (Buster)"]="https://cdimage.debian.org/images/cloud/buster/latest/debian-10-genericcloud-amd64.qcow2"
    ["Rocky Linux 9"]="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
)

DOWNLOAD_DIR="/tmp/cloud-images"
CLOUD_IMAGE_RESIZE_SIZE="18G"

function header_info {
    clear

    local PAUSE_TIME="$1"

    # Set default pause time if not provided
    if [ -z "$PAUSE_TIME" ]; then
        PAUSE_TIME=10
    fi

    # check if pause time is integer
    if ! [[ "$PAUSE_TIME" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: value '$PAUSE_TIME' is not an integer."
        exit 1
    fi
    cat << "EOF"

 /$$   /$$ /$$$$$$$$ /$$       /$$$$$$$        /$$$$$$$   /$$$$$$  /$$$$$$ /$$   /$$ /$$$$$$$$       /$$$$$$ /$$$$$$$$
| $$  | $$| $$_____/| $$      | $$__  $$      | $$__  $$ /$$__  $$|_  $$_/| $$$ | $$|__  $$__/      |_  $$_/|__  $$__/
| $$  | $$| $$      | $$      | $$  \ $$      | $$  \ $$| $$  \ $$  | $$  | $$$$| $$   | $$           | $$     | $$   
| $$$$$$$$| $$$$$   | $$      | $$$$$$$/      | $$$$$$$/| $$  | $$  | $$  | $$ $$ $$   | $$           | $$     | $$   
| $$__  $$| $$__/   | $$      | $$____/       | $$____/ | $$  | $$  | $$  | $$  $$$$   | $$           | $$     | $$   
| $$  | $$| $$      | $$      | $$            | $$      | $$  | $$  | $$  | $$\  $$$   | $$           | $$     | $$   
| $$  | $$| $$$$$$$$| $$$$$$$$| $$            | $$      |  $$$$$$/ /$$$$$$| $$ \  $$   | $$          /$$$$$$   | $$   
|__/  |__/|________/|________/|__/            |__/       \______/ |______/|__/  \__/   |__/         |______/   |__/   

                        ===### START CREATE TEMPLATE VM WITH CLOUD-INIT CONFIGURATION ###===
                   == Alma Linux, CentOS Stream, Ubuntu, OpenSUSE, Fedora, Debian, Rocky Linux ==
                                                                    by 🦣 TheRealMamuth 🦣


EOF
    sleep $1
}

function whiptail_check {
    if ! command -v whiptail &> /dev/null; then
        echo "❌ Program 'whiptail' is not installed. You can install them by run command:"
        echo "apt install whiptail"
        exit 1
    fi
}

function select_and_download_image {

    OPTIONS=()
    for name in "${!CLOUD_IMAGES_DISTROS[@]}"; do
        OPTIONS+=("$name" "")
    done

    CHOICE=$(whiptail --title "Select the cloud image" --menu "Choose an image:" 20 78 10 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ] || [ -z "$CHOICE" ]; then
        echo "Cancelled."
        exit 1
    fi
    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
}

function select_disk_size {
    while true; do
        SIZE=$(whiptail --title "Disk size" --inputbox "Set disk size, value in GB (min 10):" 10 60 10 3>&1 1>&2 2>&3)

        # For cancel
        if [ $? -ne 0 ]; then
            echo "❌ Stop script, ended."
            exit 1
        fi

        # Check if value is integer
        if ! [[ "$SIZE" =~ ^[0-9]+$ ]]; then
            whiptail --title "Error" --msgbox "Please provide integer value." 8 50
            continue
        fi

        # Check if value is greater than 10
        if [ "$SIZE" -lt 10 ]; then
            whiptail --title "Size is to small" --msgbox "Minimal size is 10 GB." 8 50
            continue
        fi

        # Set value
        CLOUD_IMAGE_RESIZE_SIZE="${SIZE}"

        clear
        header_info 2
        echo "✅ Distribution selected: $CHOICE"
        echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
        
        break
    done
}

function download_image {
    URL="${CLOUD_IMAGES_DISTROS[$CHOICE]}"
    FILENAME=$(basename "$URL")
    PATH_TO_CLOUD_IMAGE="$DOWNLOAD_DIR/$FILENAME"

    echo "Downloading: $CHOICE"
    echo "From: $URL"
    echo "To: $DOWNLOAD_DIR"
    
    mkdir -p "$DOWNLOAD_DIR"
    curl -Lo "$PATH_TO_CLOUD_IMAGE" "$URL"

    if [ $? -ne 0 ]; then
        echo "❌ Failed to download the image."
        exit 1
    else
        clear
        header_info 1
        echo "✅ Distribution selected: $CHOICE"
        echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
        echo "✅ $CHOICE Downloaded successfully."
    fi

    echo "🔧 Change disk size to ${CLOUD_IMAGE_RESIZE_SIZE}G..."
    qemu-img resize "$DOWNLOAD_DIR/$FILENAME" "${CLOUD_IMAGE_RESIZE_SIZE}"
}

function select_disk_storage {
    
    OPTIONS=()

    for storage in $(pvesh get /storage --output-format=text --noborder 1 --noheader 1); do
        info=$(pvesh get /storage/$storage --output-format=text --noborder 1 --noheader 1 2>/dev/null)
        content=$(echo "$info" | grep '^content' | cut -d' ' -f2-)
        if echo "$content" | grep -qw images; then
            type=$(echo "$info" | grep '^type' | awk '{print $2}')
            OPTIONS+=("$storage" "Typ: $type | Content: $content")
        fi
    done

    # Check if there is no storage
    if [ ${#OPTIONS[@]} -eq 0 ]; then
        whiptail --title "No Storege" --msgbox "❌ With content 'images'." 10 60
        clear
        exit 1
    fi
    
    # Menu
    VM_DISK_STORAGE=$(whiptail --title "Select storage" \
        --menu "Choice storage for your VM:" 20 70 10 \
        "${OPTIONS[@]}" \
        3>&1 1>&2 2>&3)

    # If OK and not cancel
    if [ $? -eq 0 ]; then
        clear
        header_info 1
        echo "✅ Distribution selected: $CHOICE"
        echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
        echo "✅ $CHOICE Downloaded successfully."
        echo "✅ Wybrano storage: $VM_DISK_STORAGE"
    else
        clear
        echo "❌ Script stop, ended."
        exit 1
    fi
}

function select_snippet_storage {

    # Storage with content 'snippets'
    OPTIONS=()
    for storage in $(pvesh get /storage --output-format=text --noborder 1 --noheader 1); do
        info=$(pvesh get /storage/$storage --output-format=text --noborder 1 --noheader 1 2>/dev/null)
        content=$(echo "$info" | grep '^content' | cut -d' ' -f2-)
        if echo "$content" | grep -qw snippets; then
            type=$(echo "$info" | grep '^type' | awk '{print $2}')
            OPTIONS+=("$storage" "Typ: $type | Content: $content")
        fi
    done

    # If no storage
    if [ ${#OPTIONS[@]} -eq 0 ]; then
        whiptail --title "No storage" --msgbox "❌ Not find storage with content 'snippets'." 10 60
        clear
        exit 1
    fi

    # Menu 
    SNIPPET_DISK_STORAGE=$(whiptail --title "Select Storage (Snippets)" \
        --menu "Choice storage for cloud-init snippet:" 20 70 10 \
        "${OPTIONS[@]}" \
        3>&1 1>&2 2>&3)

    # If cancel
    if [ $? -ne 0 ]; then
        clear
        echo "❌ Script ended."
        exit 1
    fi

    # Check mount point for snippets storage
    info=$(pvesh get /storage/$SNIPPET_DISK_STORAGE --output-format=text --noborder 1 --noheader 1 2>/dev/null)
    type=$(echo "$info" | grep '^type' | awk '{print $2}')

    if [ "$type" = "dir" ]; then
        base_path=$(echo "$info" | grep '^path' | awk '{print $2}')
    else
        base_path="/mnt/pve/$SNIPPET_DISK_STORAGE"
    fi

    # Snippet path
    SNIPPET_DISK_PATH="$base_path/snippets"

    # Prezentation values
    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
    echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
    echo "✅ $CHOICE Downloaded successfully."
    echo "✅ Your storage: $VM_DISK_STORAGE"
    echo "✅ Snippets storage: $SNIPPET_DISK_STORAGE"
    echo "📁 Path snippets: $SNIPPET_DISK_PATH"
}

function set_user_and_password {

    # Get username
    USERNAME=$(whiptail --title "Login for VM" \
    --inputbox "Set your user name:" 10 50 \
    3>&1 1>&2 2>&3)

    # If cancel
    if [ $? -ne 0 ]; then
        echo "❌ Script stops, ended."
        exit 1
    fi

    # Get password
    PASSWORD=$(whiptail --title "Password for VM" \
    --passwordbox "Set password:" 10 50 \
    3>&1 1>&2 2>&3)

    # if cancel
    if [ $? -ne 0 ]; then
        echo "❌ Script ended."
        exit 1
    fi

    # Presentation values
    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
    echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
    echo "✅ $CHOICE Downloaded successfully."
    echo "✅ Your storage: $VM_DISK_STORAGE"
    echo "✅ Snippets storage: $SNIPPET_DISK_STORAGE"
    echo "📁 Path snippets: $SNIPPET_DISK_PATH"
    echo "✅ Login: $USERNAME"
    echo "✅ Password: [ustawione]"
}

function set_vm_new_id {

    # Get max vmid
    max_vmid=$(pvesh get /cluster/resources --type vm --output-format=text --noborder 1 --noheader 1 \
    | awk '{split($1, id, "/"); print id[2]}' \
    | sort -n | tail -n1)

    # Set new vmid
    if [ -z "$max_vmid" ]; then
    max_vmid=100
    else
    max_vmid=$((max_vmid + 1))
    fi

    # You can change the default value
    VMID=$(whiptail --title "Set VMID" \
    --inputbox "Set ne ID (You can change):" 10 60 "$max_vmid" \
    3>&1 1>&2 2>&3)

    # If cancel
    if [ $? -ne 0 ]; then
        echo "❌ Wybór został anulowany."
        exit 1
    fi

    # Check if value is integer
    if ! [[ "$VMID" =~ ^[0-9]+$ ]]; then
        whiptail --title "Error" --msgbox "❌ The value is not integer!" 10 60
        exit 1
    fi

    # Presentation values
    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
    echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
    echo "✅ $CHOICE Downloaded successfully."
    echo "✅ Your storage: $VM_DISK_STORAGE"
    echo "✅ Snippets storage: $SNIPPET_DISK_STORAGE"
    echo "📁 Path snippets: $SNIPPET_DISK_PATH"
    echo "✅ Login: $USERNAME"
    echo "✅ Password: [ustawione]"
    echo "✅ VMID: $VMID"
}

function set_network_interface {
    # Default value for network interface
    DEFAULT_BRIDGE="vmbr0"

    # Get network interface
    NETWORK_IFACE=$(whiptail --title "Interfejs sieciowy" \
    --inputbox "Podaj nazwę interfejsu sieciowego (bridge), np. vmbr0:" 10 60 "$DEFAULT_BRIDGE" \
    3>&1 1>&2 2>&3)

    # If cancel
    if [ $? -ne 0 ]; then
        echo "❌ Wybór został anulowany."
        exit 1
    fi

    # Walidate network interface name
    if [ -z "$NETWORK_IFACE" ]; then
        whiptail --title "Error" --msgbox "❌ Wrong interface name!" 10 60
        exit 1
    fi

    # Presentation values
    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
    echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
    echo "✅ $CHOICE Downloaded successfully."
    echo "✅ Your storage: $VM_DISK_STORAGE"
    echo "✅ Your snippets storage: $SNIPPET_DISK_STORAGE"
    echo "📁 Path snippets: $SNIPPET_DISK_PATH"
    echo "✅ Login: $USERNAME"
    echo "✅ Password: [ustawione]"
    echo "✅ VMID: $VMID"
    echo "✅ Network interface: $NETWORK_IFACE"
}

function set_memory_cpu {
    # Default values
    DEFAULT_RAM=1024
    DEFAULT_SOCKETS=1
    DEFAULT_CORES=2

    # RAM
    RAM=$(whiptail --title "RAM (MB)" \
    --inputbox "Set RAM for VM (in MB):" 10 60 "$DEFAULT_RAM" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ] || ! [[ "$RAM" =~ ^[0-9]+$ ]]; then
        whiptail --msgbox "❌ ERROR: RAM must be a integer!" 10 60
        exit 1
    fi

    # SOCKETS
    SOCKETS=$(whiptail --title "Socket" \
    --inputbox "Set socket number (ex. 1):" 10 60 "$DEFAULT_SOCKETS" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ] || ! [[ "$SOCKETS" =~ ^[0-9]+$ ]]; then
        whiptail --msgbox "❌ Error: Number of socket must be a integer!" 10 60
        exit 1
    fi

    # CORES
    CORES=$(whiptail --title "Set Cores" \
    --inputbox "Set cores per socket (ex. 2):" 10 60 "$DEFAULT_CORES" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ] || ! [[ "$CORES" =~ ^[0-9]+$ ]]; then
        whiptail --msgbox "❌ Error: Cores number must be a integer!" 10 60
        exit 1
    fi

    # Sukces
    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
    echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
    echo "✅ $CHOICE Downloaded successfully."
    echo "✅ Your storage: $VM_DISK_STORAGE"
    echo "✅ Snippet storage: $SNIPPET_DISK_STORAGE"
    echo "📁 Path snippets: $SNIPPET_DISK_PATH"
    echo "✅ Login: $USERNAME"
    echo "✅ Password: [ustawione]"
    echo "✅ VMID: $VMID"
    echo "✅ Network interfaces: $NETWORK_IFACE"
    echo "✅ Virtual MAchine parameters:"
    echo "   RAM:     $RAM MB"
    echo "   Socket:  $SOCKETS"
    echo "   Core:    $CORES"
}

function create_vm_with_cloudinit {

    # Create snippet storage
    mkdir -p "$SNIPPET_DISK_PATH"

    # Set name template
    NAME_TEMPLATE=$(echo "$CHOICE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

    # Set path
    DOWNLOAD_PATH="$DOWNLOAD_DIR"
    IMAGE_FILENAME=$(basename "${CLOUD_IMAGES_DISTROS[$CHOICE]}")
    IMAGE_PATH="$DOWNLOAD_PATH/$IMAGE_FILENAME"

    # Create VM
    echo "---> Set VM z ID: ${VMID}"
    qm create ${VMID} \
        --name "${NAME_TEMPLATE}-${VMID}-cloudinit" \
        --ostype l26 \
        --memory ${RAM} \
        --agent enabled=1,fstrim_cloned_disks=1 \
        --bios ovmf \
        --machine q35 \
        --efidisk0 ${VM_DISK_STORAGE}:0,pre-enrolled-keys=0 \
        --cpu host \
        --sockets ${SOCKETS} \
        --cores ${CORES} \
        --net0 virtio,bridge=${NETWORK_IFACE},firewall=1

    # Import disk
    echo "---> Import disk to Storage: ${VM_DISK_STORAGE}"
    qm importdisk ${VMID} "$IMAGE_PATH" "${VM_DISK_STORAGE}"

    # set disk size
    echo "---> Connect disk to VM"
    qm set ${VMID} --scsihw virtio-scsi-pci --virtio0 ${VM_DISK_STORAGE}:vm-${VMID}-disk-1,discard=on

    # Set boot order
    echo "---> Set boot order"
    qm set ${VMID} --boot order=virtio0

    # Cloud-init disk
    echo "---> Set cloud-init"
    qm set ${VMID} --ide2 ${VM_DISK_STORAGE}:cloudinit

    # Create cloud-init vendor.yaml
    echo "---> Create cloud-init vendor.yaml"
    cat << EOF > "${SNIPPET_DISK_PATH}/vendor-${NAME_TEMPLATE}.yaml"
#cloud-config
write_files:
  - path: /usr/local/bin/install-qemu-guest-agent.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      LOG_FILE="/var/log/cloud-init-raport.log"
      ERR_FILE="/var/log/error-cloud-init-raport.log"

      touch "$$LOG_FILE" "$$ERR_FILE"

      {
        echo "=== Installation qemu-guest-agent: $$(date) ==="

        # Identify OS
        if [ -f /etc/os-release ]; then
          source /etc/os-release
          echo "Operation System: $$NAME $$VERSION"
        fi

        INSTALL_SUCCESS="false"

        if command -v apt >/dev/null 2>&1; then
          echo "APT (Debian/Ubuntu)"
          apt update && apt install -y qemu-guest-agent && INSTALL_SUCCESS="true"
        elif command -v dnf >/dev/null 2>&1; then
          echo "DNF (Fedora/CentOS/AlmaLinux)"
          dnf install -y qemu-guest-agent && INSTALL_SUCCESS="true"
        elif command -v zypper >/dev/null 2>&1; then
          echo "ZYPPER (openSUSE)"
          zypper install -y qemu-guest-agent && INSTALL_SUCCESS="true"
        else
          echo "❌ Other package manager, I don't install qemu-guest-agent." >&2
        fi

        if [[ "$$INSTALL_SUCCESS" == "true" ]] && command -v qemu-ga >/dev/null 2>&1; then
          systemctl enable --now qemu-guest-agent
          echo "✅ qemu-guest-agent installed and run."
        else
          echo "❌ Failed installed qemu-guest-agent." >&2
        fi

        echo "=== End: $$(date) ==="
      } >> "$$LOG_FILE" 2>> "$$ERR_FILE"

runcmd:
  - /usr/local/bin/install-qemu-guest-agent.sh
  - reboot
EOF

    # Config cloud-init
    echo "---> Konfiguracja cloud-init"
    qm set ${VMID} --cicustom "vendor=${SNIPPET_DISK_STORAGE}:snippets/vendor-${NAME_TEMPLATE}.yaml"
    qm set ${VMID} --tags "${NAME_TEMPLATE},cloudinit"
    qm set ${VMID} --ciuser "$USERNAME" --ciupgrade 1
    qm set ${VMID} --cipassword "$(openssl passwd -6 "$PASSWORD")"
    qm set ${VMID} --sshkeys ~/.ssh/authorized_keys
    qm set ${VMID} --ipconfig0 ip=dhcp

    # Update cloud-init
    echo "---> Aktualizacja cloud-init VM"
    qm cloudinit update ${VMID}

    # Create template
    echo "---> Tworzenie szablonu z VM ${VMID}"
    qm template ${VMID}

    # Clean up
    echo "---> Czyszczenie pobranego obrazu"
    rm -f "$IMAGE_PATH"

    clear
    header_info 1
    echo "✅ Distribution selected: $CHOICE"
    echo "✅ Disk size: ${CLOUD_IMAGE_RESIZE_SIZE} GB"
    echo "✅ $CHOICE Downloaded successfully."
    echo "✅ Your storage: $VM_DISK_STORAGE"
    echo "✅ Snippets storage: $SNIPPET_DISK_STORAGE"
    echo "📁 Path snippets: $SNIPPET_DISK_PATH"
    echo "✅ Login: $USERNAME"
    echo "✅ Password: [ustawione]"
    echo "✅ VMID: $VMID"
    echo "✅ WNetwork Interface: $NETWORK_IFACE"
    echo "✅ Virtual Machine:"
    echo "   RAM:     $RAM MB"
    echo "   Socket:  $SOCKETS"
    echo "   Core:    $CORES"
    echo "✅ Template created: ${VMID}"
}

header_info 1
whiptail_check
select_and_download_image
download_image
select_disk_storage
select_snippet_storage
set_user_and_password
set_vm_new_id
set_network_interface
set_memory_cpu
create_vm_with_cloudinit
