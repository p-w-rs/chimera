#!/usr/bin/env fish

# mkimg.fish — create and partition a raw disk image for Linux.
# Attaches a loop device, writes GPT (EFI + swap + root), formats all three.
# Output: void.img attached at a loop device (printed at the end).
#
# To adjust image or partition sizes, edit the variables below.
# After this script: run install-pkgs, then run-chroot.

source (dirname (status filename))/helpers/die.fish
set CALC (dirname (status filename))/helpers/mbcalc.fish

# ── Configuration ─────────────────────────────────────────────────────────────
set IMG_FILE  linux.img
set IMG_SIZE  64G
set EFI_SIZE  1G
set SWAP_SIZE 8G

# ── Partition layout ──────────────────────────────────────────────────────────
set EFI_MB  (run $CALC $EFI_SIZE)
set SWAP_MB (run $CALC $SWAP_SIZE)

set EFI_START  1M
set EFI_END    (math "1 + $EFI_MB")M
set SWAP_END   (math "1 + $EFI_MB + $SWAP_MB")M

# ── Create image and attach loop device ───────────────────────────────────────
echo "Creating $IMG_SIZE disk image: $IMG_FILE..."
run truncate -s $IMG_SIZE $IMG_FILE

echo "Attaching loop device..."
set LOOP (doas losetup --find --partscan --show $IMG_FILE)
or die "losetup failed"
echo "Loop device: $LOOP"

# ── Partition and format ───────────────────────────────────────────────────────
# Layout: 1M gap | EFI (FAT32) | swap | root (ext4, rest of disk)
echo "Partitioning $LOOP..."
run doas parted --script $LOOP \
    mklabel gpt \
    mkpart EFI  fat32      $EFI_START $EFI_END  \
    mkpart swap linux-swap $EFI_END   $SWAP_END \
    mkpart root ext4       $SWAP_END  100%      \
    set 1 esp on

sleep 1

echo "Formatting partitions..."
run doas mkfs.vfat -F32 -n EFI  {$LOOP}p1
run doas mkswap    -L   swap    {$LOOP}p2
run doas mkfs.ext4 -L   root    {$LOOP}p3

echo ""
echo "Done. Loop device: $LOOP"
echo "Detach when finished: doas losetup -d $LOOP"
