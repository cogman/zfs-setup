UUID=t77my4
DISK=/dev/disk/by-id/scsi-SATA_Samsung_SSD_870_S5VWNG0NB01146K

apt update && apt upgrade --yes
gsettings set org.gnome.desktop.media-handling automount false

apt install --yes debootstrap gdisk zfs-initramfs zfs-zed

systemctl stop zed

while read -r record; do
  sgdisk --zap-all "$record"
  sgdisk -n1:1M:+512M -t1:EF00 "$record"
  sgdisk -n2:0:+300M  -t2:BE00 "$record"
  sgdisk -n3:0:0      -t3:BF00 "$record"
done < disks

echo 'Setting up bpool'

zpool create \
    -o cachefile=/etc/zfs/zpool.cache \
    -o ashift=13 -o autotrim=on -d \
    -o feature@async_destroy=enabled \
    -o feature@bookmarks=enabled \
    -o feature@embedded_data=enabled \
    -o feature@empty_bpobj=enabled \
    -o feature@enabled_txg=enabled \
    -o feature@extensible_dataset=enabled \
    -o feature@filesystem_limits=enabled \
    -o feature@hole_birth=enabled \
    -o feature@large_blocks=enabled \
    -o feature@lz4_compress=enabled \
    -o feature@spacemap_histogram=enabled \
    -O acltype=posixacl -O canmount=off -O compression=lz4 \
    -O devices=off -O normalization=formD -O relatime=on -O xattr=sa \
    -O mountpoint=/boot -R /mnt \
    -f bpool raidz2 \
    `cat bpoolPart`