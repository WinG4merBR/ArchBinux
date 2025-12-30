#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Mapping additional disks via hardware ID"

FSTAB="/etc/fstab"

[[ -d /etc ]] || { echo "[FATAL] /etc not found"; exit 1; }
touch "$FSTAB" || { echo "[FATAL] Cannot write /etc/fstab"; exit 1; }

# Seagate ST1000DM003
SERIAL_GAMES="S1DG7P6T"
SERIAL_DATA="S1DFBD8C"

# NVMe root disk
SERIAL_NVME="KM402LAK2SWX"


MP_GAMES="/mnt/games"
MP_STUFF="/mnt/stuff"
MP_DEV="/mnt/dev"

FS_GAMES="ext4"
FS_NTFS="ntfs-3g"

fail() {
    echo "[FATAL] $1" >&2
    exit 1
}

find_disk_by_serial() {
    local serial="$1"

    for dev in /dev/disk/by-id/*; do
        if udevadm info --query=property --name="$dev" 2>/dev/null \
            | grep -q "ID_SERIAL_SHORT=$serial"; then
            readlink -f "$dev"
            return 0
        fi
    done

    return 1
}

get_partition() {
    local disk="$1"
    local part="$2"

    # NVMe naming handling
    if [[ "$disk" == *"nvme"* ]]; then
        echo "${disk}p${part}"
    else
        echo "${disk}${part}"
    fi
}

get_uuid() {
    blkid -s UUID -o value "$1" || return 1
}

ensure_mountpoint() {
    mkdir -p "$1"
}

append_fstab() {
    local uuid="$1"
    local mount="$2"
    local fs="$3"
    local opts="$4"
    local pass="$5"

    if grep -q "UUID=$uuid" "$FSTAB"; then
        echo "[WARN] UUID $uuid already present in fstab, skipping"
        return
    fi

    echo "UUID=$uuid  $mount  $fs  $opts  0  $pass" >> "$FSTAB"
}

echo "[INFO] Resolving disks..."

DISK_GAMES="$(find_disk_by_serial "$SERIAL_GAMES")" \
    || fail "Games disk not found (serial $SERIAL_GAMES)"

DISK_DATA="$(find_disk_by_serial "$SERIAL_DATA")" \
    || fail "Data disk not found (serial $SERIAL_DATA)"

DISK_NVME="$(find_disk_by_serial "$SERIAL_NVME")" \
    || fail "NVMe disk not found (serial $SERIAL_NVME)"

echo "[OK] Games disk : $DISK_GAMES"
echo "[OK] Data disk  : $DISK_DATA"
echo "[OK] NVMe disk  : $DISK_NVME"

PART_GAMES="$(get_partition "$DISK_GAMES" 1)"
PART_STUFF="$(get_partition "$DISK_DATA" 2)"
PART_DEV="$(get_partition "$DISK_DATA" 3)"

UUID_GAMES="$(get_uuid "$PART_GAMES")" \
    || fail "Failed to read UUID for games partition"

UUID_STUFF="$(get_uuid "$PART_STUFF")" \
    || fail "Failed to read UUID for stuff partition"

UUID_DEV="$(get_uuid "$PART_DEV")" \
    || fail "Failed to read UUID for dev partition"

ensure_mountpoint "$MP_GAMES"
ensure_mountpoint "$MP_STUFF"
ensure_mountpoint "$MP_DEV"


echo "[INFO] Updating /etc/fstab"

append_fstab "$UUID_GAMES" "$MP_GAMES" "$FS_GAMES" "defaults,rw,exec" 2
append_fstab "$UUID_STUFF" "$MP_STUFF" "$FS_NTFS" "rw,uid=1000,gid=1000,umask=022,windows_names,nofail" 0
append_fstab "$UUID_DEV"   "$MP_DEV"   "$FS_NTFS" "rw,uid=1000,gid=1000,umask=022,windows_names,nofail" 0

echo "Have fun!"