#!/usr/bin/env fish

# mount.fish — mount a partitioned Void Linux disk under /mnt.
# Mounts root → /mnt, EFI → /mnt/boot/efi, and enables swap.
#
# Usage: ./mount.fish <device>
#   ./mount.fish /dev/loop0      (disk image)
#   ./mount.fish /dev/sda        (SATA/SCSI)
#   ./mount.fish /dev/nvme0n1    (NVMe)

source (dirname (status filename))/helpers/die.fish

test (count $argv) -eq 1; or die "Usage: "(status filename)" <device>"
set DEV $argv[1]

# NVMe/loop devices use 'p' before the partition number
if string match -qr '(nvme|loop)' $DEV
    set P {$DEV}p
else
    set P $DEV
end

echo "Mounting $DEV → /mnt..."
run doas mount      {$P}3 /mnt
run doas mkdir -p   /mnt/boot/efi
run doas mount      {$P}1 /mnt/boot/efi
run doas swapon     {$P}2

echo ""
echo "Mounted. To unmount when finished:"
echo "  doas swapoff {$P}2 && doas umount /mnt/boot/efi && doas umount /mnt"
