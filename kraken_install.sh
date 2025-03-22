#!/bin/bash



RED='\033[0;31m'
NC='\033[0m'
usage() {
    echo "Usage: $0 <disk> <home_on(yes/no)> <swap_on(yes/no)>"
    echo "Example: $0 /dev/sda yes no"
    echo "Parameters:"
    echo "  <disk>        Target disk to partition (e.g., /dev/sda)"
    echo "  <home_on>     Create home partition? (yes/no)"
    echo "  <swap_on>     Create swap partition? (yes/no)"
    exit 1
}


validate_parameters() {
    # Check for help request
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        usage
    fi

    # Check number of parameters
    if [ $# -ne 9 ]; then
        echo -e "${RED}Error: Missing parameters${NC}"
        usage
    fi

    # Check disk exists
    if [ ! -b "$1" ]; then
        echo -e "${RED}Error: Invalid disk device $1${NC}"
        usage
    fi

    # Validate yes/no parameters
    if [[ "$2" != "yes" && "$2" != "no" ]]; then
        echo -e "${RED}Error: home_on must be 'yes' or 'no'${NC}"
        usage
    fi

    if [[ "$3" != "yes" && "$3" != "no" ]]; then
        echo -e "${RED}Error: swap_on must be 'yes' or 'no'${NC}"
        usage
    fi
}


validate_parameters "$@"

DISK=$1  #valid  /dev/sda
home_on=$2  #valid yes ,no 
swap_on=$3  #valid yes , no 
username=$4 
userpass=$5
language=$6 #valid en_US.UTF-8 ,fr_FR.UTF-8,ar_SA.UTF-8
keyboard=$7 # valid keyboard us, fr 
hostname=$8
timezone=$9 #valid /Africa/Tunis 
echo "Welcome to Kraken OS"
mkdir -p /home/kraken  

echo "Disk partitioning..."

# case one ----------------------------------------------------
if [ "$swap_on" == "yes" ] && [ "$home_on" == "yes" ]; then
    echo "Creating partitions with both swap and home..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=25G, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root
size=2G, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name=swap
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=home" | sfdisk "$DISK"
    
    sleep 3
    echo "Formatting partitions..."
    mkfs.ext4 -F "${DISK}2"  
    mkswap "${DISK}3"
    mkfs.ext4 -F "${DISK}4"
    echo "Partitioning and formatting completed."
 

    echo "mounting root partition ..."
    mount "${DISK}2" /home/kraken


echo "copy file systems"
echo -e "\033[34mPlease wait. The process can take some time; if you are using an SDD, it may take about 15 minutes.\033[0m"
sleep 5
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken


echo "copy kernla image .."
rm -Rf /home/kraken/boot/*
cp /boot/System.map-6.10.5  /home/kraken/boot/
cp /boot/config-6.10.5  /home/kraken/boot/
cp /boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/
mv /home/kraken/boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/vmlinuz-6.10.5-kraken-1.0


echo "mounting ..."
mount --bind /dev /home/kraken/dev
mount --bind /proc /home/kraken/proc
mount --bind /sys /home/kraken/sys

echo "chroot to the new system "
chroot /home/kraken /bin/bash << CHROOT_EOF

grub-install "$DISK"
sleep 3 



cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)

insmod efi_gop
insmod efi_uga
if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}

menuentry "Firmware Setup" {
  fwsetup
}

EOF

rm -Rf /etc/fstab

cat > /etc/fstab << EOF
# Begin /etc/fstab
# el  dinary mara men houna
# file system  mount-point    type     options             dump  fsck
#                                                                order

${DISK}2      /              ext4     defaults            1     1
${DISK}3      swap           swap     pri=1               0     0
#/dev/sda1      /boot/efi      vfat     codepage=437,iocharset=iso8859-1            0     1
${DISK}4      /home          ext4     defaults            1     2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
#efivarfs /sys/firmware/efi/efivars efivarfs defaults 0 0

EOF

echo "creating user ..."
useradd -m -G wheel,input,audio,sddm,seat,tty,lpadmin "$username"
echo "$username:$userpass" | chpasswd
mount "${DISK}4" /home 
mkdir /home/"$username"
chown "$username":"$username" /home/"$username"

cp /root/.xinitrc /home/"$username"/
cp /root/.Xauthority /home/"$username"/
sleep 2 
umount -R "${DISK}4"




echo "Configure Hostname"
echo "$hostname" > /etc/hostname

echo "Configure system language "
echo "LANG=$language" > /etc/locale.conf
echo "LC_ALL=$language" >> /etc/locale.conf
localedef -i "${language%.*}" -f UTF-8 "$language"

echo "Configure timezone "

ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

echo " Configure location "

echo "Configure keyboard "
echo "KEYMAP=$keyboard" > /etc/vconsole.conf
loadkeys "$keyboard"

echo "delete live users ..."
userdel -r pfe
userdel -r cracken 
userdel -r nacef


echo "enable sddm services ..."
sed -i 's/^#exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/' /etc/rc.d/init.d/xdm

CHROOT_EOF

umount -R /home/kraken


fi





#case 2 --------------------------------------

if [ "$home_on" == "yes" ] && [ "$swap_on" == "no" ]; then
    echo "Creating partitions with home (no swap)..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=25G, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=home" | sfdisk "$DISK"
    
    sleep 3
    echo "Formatting partitions..."
    mkfs.ext4 -F "${DISK}2"
    mkfs.ext4 -F  "${DISK}3"
    echo "Partitioning and formatting completed."
    
    echo "mounting root partition ..."
    mount "${DISK}2" /home/kraken


   

echo "copy file systems"
echo -e "\033[34mPlease wait. The process can take some time; if you are using an SDD, it may take about 15 minutes.\033[0m"
sleep 4
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken


echo "copy kernla image .."
rm -Rf /home/kraken/boot/* 
cp /boot/System.map-6.10.5  /home/kraken/boot/
cp /boot/config-6.10.5  /home/kraken/boot/
cp /boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/
mv /home/kraken/boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/vmlinuz-6.10.5-kraken-1.0


echo "mounting ..."
mount --bind /dev /home/kraken/dev
mount --bind /proc /home/kraken/proc
mount --bind /sys /home/kraken/sys

echo "chroot to the new system "
chroot /home/kraken  /bin/bash << CHROOT_EOF

grub-install "$DISK"
sleep 3
cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)

insmod efi_gop
insmod efi_uga
if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}

menuentry "Firmware Setup" {
  fwsetup
}

EOF

rm -Rf /etc/fstab 

cat > /etc/fstab << EOF
# Begin /etc/fstab
# el  dinary mara men houna 
# file system  mount-point    type     options             dump  fsck
#                                                                order

${DISK}2      /              ext4     defaults            1     1
#/dev/sda3      swap           swap     pri=1               0     0
#/dev/sda1      /boot/efi      vfat     codepage=437,iocharset=iso8859-1            0     1
${DISK}3      /home          ext4     defaults            1     2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
#efivarfs /sys/firmware/efi/efivars efivarfs defaults 0 0

EOF

echo "creating user ..."
useradd -m -G wheel,input,audio,sddm,seat,tty,lpadmin "$username"
echo "$username:$userpass" | chpasswd

cp /root/.xinitrc /home/"$username"/

echo "Configure Hostname"
echo "$hostname" > /etc/hostname

echo "Configure system language "
echo "LANG=$language" > /etc/locale.conf
echo "LC_ALL=$language" >> /etc/locale.conf
localedef -i "${language%.*}" -f UTF-8 "$language"

echo "Configure timezone "

ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

echo " Configure location "

echo "Configure keyboard "
echo "KEYMAP=$keyboard" > /etc/vconsole.conf
loadkeys "$keyboard"

echo "enable sddm services "
sed -i 's/^#exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/' /etc/rc.d/init.d/xdm


CHROOT_EOF

umount -R /home/kraken




fi
































#case 3 -------------------------------------
if [ "$home_on" == "no" ] && [ "$swap_on" == "yes" ]; then
    echo "Creating partitions with swap (no home)..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=2G, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name=swap
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root" | sfdisk "$DISK"
    
    sleep 3
    echo "Formatting partitions..."
    mkswap "${DISK}2"
    mkfs.ext4 -F  "${DISK}3"
    echo "Partitioning and formatting completed."

    
    echo "mounting root partition ..."
    mount "${DISK}3" /home/kraken

   echo "copy file systems"
echo -e "\033[34mPlease wait. The process can take some time; if you are using an SDD, it may take about 15 minutes.\033[0m"
sleep 4
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken


echo "copy kernla image .."
rm -Rf /home/kraken/boot/* 
cp /boot/System.map-6.10.5  /home/kraken/boot/
cp /boot/config-6.10.5  /home/kraken/boot/
cp /boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/
mv /home/kraken/boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/vmlinuz-6.10.5-kraken-1.0


echo "mounting ..."
mount --bind /dev /home/kraken/dev
mount --bind /proc /home/kraken/proc
mount --bind /sys /home/kraken/sys

echo "chroot to the new system "
chroot /home/kraken  /bin/bash << CHROOT_EOF

grub-install "$DISK"
 sleep 3 
cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,3)

insmod efi_gop
insmod efi_uga
if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}3 ro
}

menuentry "Firmware Setup" {
  fwsetup
}

EOF

rm -Rf /etc/fstab 

cat > /etc/fstab << EOF
# Begin /etc/fstab
# el  dinary mara men houna 
# file system  mount-point    type     options             dump  fsck
#                                                                order

${DISK}3      /              ext4     defaults            1     1
${DISK}2      swap           swap     pri=1               0     0
#/dev/sda1      /boot/efi      vfat     codepage=437,iocharset=iso8859-1            0     1
#/dev/sda5      /home          ext4     defaults            1     2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
#efivarfs /sys/firmware/efi/efivars efivarfs defaults 0 0

EOF

echo "creating user ..."
useradd -m -G wheel,input,audio,sddm,seat,tty,lpadmin "$username"
echo "$username:$userpass" | chpasswd

cp /root/.xinitrc /home/"$username"/

echo "Configure Hostname"
echo "$hostname" > /etc/hostname

echo "Configure system language "
echo "LANG=$language" > /etc/locale.conf
echo "LC_ALL=$language" >> /etc/locale.conf
localedef -i "${language%.*}" -f UTF-8 "$language"

echo "Configure timezone "

ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

echo " Configure location "

echo "Configure keyboard "
echo "KEYMAP=$keyboard" > /etc/vconsole.conf
loadkeys "$keyboard"

echo "enable sddm deamon "
sed -i 's/^#exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/' /etc/rc.d/init.d/xdm

CHROOT_EOF

umount -R /home/kraken

fi









#case 4 -------------------------
if [ "$home_on" == "no" ] && [ "$swap_on" == "no" ]; then
    echo "Creating partitions without swap or home..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root" | sfdisk "$DISK"
    
    sleep 3
    echo "Formatting partitions..."
    mkfs.ext4 -F  "${DISK}2"  # Fixed typo: mfks -> mkfs
    echo "Partitioning and formatting completed."


    echo "mounting root partition ..."
   # echo "mounting root partition ..."
    mount "${DISK}2" /home/kraken












echo "copy file systems"
echo -e "\033[34mPlease wait. The process can take some time; if you are using an SDD, it may take about 15 minutes.\033[0m"
sleep 4
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken


echo "copy kernla image .."
rm -Rf /home/kraken/boot/* 
cp /boot/System.map-6.10.5  /home/kraken/boot/
cp /boot/config-6.10.5  /home/kraken/boot/
cp /boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/
mv /home/kraken/boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/vmlinuz-6.10.5-kraken-1.0


echo "mounting ..."
mount --bind /dev /home/kraken/dev
mount --bind /proc /home/kraken/proc
mount --bind /sys /home/kraken/sys

echo "chroot to the new system "
chroot /home/kraken  /bin/bash << CHROOT_EOF

grub-install "$DISK"
sleep 2 

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)

insmod efi_gop
insmod efi_uga
if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}

menuentry "Firmware Setup" {
  fwsetup
}

EOF

rm -Rf /etc/fstab 

cat > /etc/fstab << EOF
# Begin /etc/fstab
# el  dinary mara men houna 
# file system  mount-point    type     options             dump  fsck
#                                                                order

${DISK}2      /              ext4     defaults            1     1
#/dev/sda3      swap           swap     pri=1               0     0
#/dev/sda1      /boot/efi      vfat     codepage=437,iocharset=iso8859-1            0     1
#/dev/sda5      /home          ext4     defaults            1     2
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
#efivarfs /sys/firmware/efi/efivars efivarfs defaults 0 0

EOF

echo "creating user ..."
useradd -m -G wheel,input,audio,sddm,seat,tty,lpadmin "$username"
echo "$username:$userpass" | chpasswd

cp /root/.xinitrc /home/"$username"/

echo "Configure Hostname"
echo "$hostname" > /etc/hostname

echo "Configure system language "
echo "LANG=$language" > /etc/locale.conf
echo "LC_ALL=$language" >> /etc/locale.conf
localedef -i "${language%.*}" -f UTF-8 "$language"

echo "Configure timezone "

ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

echo " Configure location "

echo "Configure keyboard "
echo "KEYMAP=$keyboard" > /etc/vconsole.conf
loadkeys "$keyboard"

echo "enable sddm services"
sed -i 's/^#exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/exec \${DISPLAY_MANAGER} \${DM_OPTIONS}/' /etc/rc.d/init.d/xdm

CHROOT_EOF

fi



echo -e "\033[34m installation done successfully .\033[0m"

exit 0
