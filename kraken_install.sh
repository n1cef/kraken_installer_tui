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
    
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        usage
    fi

    
    if [ $# -ne 10 ]; then
        echo -e "${RED}Error: Missing parameters${NC}"
        usage
    fi

    
    if [ ! -b "$1" ]; then
        echo -e "${RED}Error: Invalid disk device $1${NC}"
        usage
    fi

   
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
packages=${10} # array of packages needed by the user to  take nobel prize 

echo "Welcome to Kraken OS"
mkdir -p /home/kraken  

echo "Disk partitioning..."

# case one ----------------------------------------------------
if [ "$swap_on" == "yes" ] && [ "$home_on" == "yes" ]; then
	echo "PROGRESS:0:Starting installation..."
    echo "Creating partitions with both swap and home..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=35G, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root
size=2G, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name=swap
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=home" | sfdisk "$DISK"
    
    sleep 3
    echo "PROGRESS:25:Disk partitioned"
    echo "Formatting partitions..."
    mkfs.ext4 -F "${DISK}2"  
    mkswap "${DISK}3"
    mkfs.ext4 -F "${DISK}4"
    echo "Partitioning and formatting completed."
 

    echo "mounting root partition ..."
    mount "${DISK}2" /home/kraken

  

echo "PROGRESS:40:Prepare Files system"

#echo -e "\e[34mPlease wait. The process can take some time; if you are using an SSD, it may take about 15 minutes.\e[0m"
sleep 5
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken

echo "PROGRESS:70:Configure Bootloader"
echo "copy kernel image .."
rm -Rf /home/kraken/boot/*
cp /boot/System.map-6.10.5  /home/kraken/boot/
cp /boot/config-6.10.5  /home/kraken/boot/
cp /boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/
mv /home/kraken/boot/vmlinuz-6.10.5-lfs-12.2 /home/kraken/boot/vmlinuz-6.10.5-kraken-1.0


echo "mounting ..."
mount --bind /dev /home/kraken/dev
mount --bind /proc /home/kraken/proc
mount --bind /sys /home/kraken/sys
mount --bind /dev/pts /home/kraken/dev/pts
mount --bind /dev/shm /home/kraken/dev/shm
mount --bind /sys/fs/cgroup /home/kraken/sys/fs/cgroup
mount -t tmpfs tmpfs /home/kraken/run
echo "PROGRESS:50:Packages installed"
echo "chroot to the new system "
chroot /home/kraken /bin/bash << CHROOT_EOF

grub-install "$DISK"
sleep 3 
cp -r /usr/share/grub/themes /boot/grub/
sleep 2
mkdir -p  /boot/grub/fonts
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_90.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_54.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_20.pf2 /boot/grub/fonts/

sleep 3 


cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)
insmod vbe
set gfxmode=1024x768
insmod gfxterm
terminal_output gfxterm
insmod font
insmod efi_gop
insmod efi_uga
loadfont /boot/grub/fonts/dersu_uzala_brush_16.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_54.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_60.pf2
loadfont /boot/grub/fonts/fira_code_16.pf2
loadfont /boot/grub/fonts/fira_code_20.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_100.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_90.pf2

insmod png
set theme=/boot/grub/themes/kraken_grub_theme/theme.txt

if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}
menuentry "kraken os (Debug) " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}

menuentry "kraken os (Ram)" {
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
useradd -m -G wheel,input,audio,sddm,seat,tty,video,lpadmin "$username"
echo "$username:$userpass" | chpasswd
mount "${DISK}4" /home 
mkdir /home/"$username"
chown "$username":"$username" /home/"$username"

cp /root/.xinitrc /home/"$username"/
cp /root/.Xauthority /home/"$username"/


mkdir -pv "/home/$username/.config"
mkdir -pv "/home/$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config"
chown "$username":"$username" /home/"$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config/alacritty.toml"

cat > "/home/$username/.config/alacritty/alacritty.toml" << 'EOF'
[shell]
program = "bash"
args = ["-c", "fastfetch; exec bash"]
EOF

/usr/bin/alacritty migrate


cp "/home/$username/.bashrc" "/home/$username/.bashrc.bak"

cat > "/home/$username/.bashrc" << 'EOF'
# Optimize build jobs
export MAKEFLAGS="-j$(nproc)"

# Custom prompt (color codes embedded directly in PS1)
if [[ $EUID == 0 ]]; then
    PS1="\[\e[1;31m\]\u [ \[\e[0m\]\w\[\e[1;31m\] ]# \[\e[0m\]"
else
    PS1="\[\e[1;32m\]\u [ \[\e[0m\]\w\[\e[1;32m\] ]\$ \[\e[0m\]"
fi


unset script


export WLR_NO_HARDWARE_CURSORS="1"  
export GDK_BACKEND="wayland"        
EOF


chown "$username":"$username" /home/"$username/.bashrc"
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
rm -Rf /etc/rc.d/init.d/startkde

CHROOT_EOF

chroot /home/kraken /bin/bash -c "alacritty migrate "



echo "PROGRESS:72:This will take some time based on your selected packages."
sleep 6

echo "PROGRESS:75:Note that we build packages from source..."
sleep 6
echo "PROGRESS:78:So This might take years... as he takes my entire life! :)"
sleep 8
echo "PROGRESS:79:Selected packages"
echo -e "\nSelected Packages:"
if [ -n "$packages" ]; then
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do
        echo " - $pkg"
    done
else
    echo "No packages selected"
fi  

sleep 8

echo "PROGRESS:80:Installing Packages ..."
if [ -n "$packages" ]; then

    declare -A base_packages=(
        [gcc]=1 [clang]=1 [rustc]=1 [llvm]=1 [gc]=1 
        [vim]=1 [cmake]=1 [ninja]=1 [meson]=1 [git]=1 
        [gdb]=1 [strace]=1 [python3]=1 [npm]=1 [pip]=1 
        [cargo]=1 [sqlite3]=1 [curl]=1 [wget]=1
    )

    declare -A non_ready_packages=(
   
    [composer]=1 [gin]=1  [restapi]=1  [jest]=1 
    [cypress]=1  [mariadb]=1 [docker]=1 [azurcli]=1  [googlecloudsdk]=1 
    [grafana]=1  [nagios]=1 [prometheus]=1 
    [react-nativeb]=1 [wireshark]=1
    [nmap]=1  [openvpn]=1 [netcat]=1 
    [wireguard]=1  [metasploit]=1 [burpsuite]=1 
    [jhontheripper]=1 [aircrack]=1  [hashcat]=1  [scikitlearn]=1 
    [tensorflow]=1 [pytorch]=1  [panda]=1  [numpy]=1 
    [matplotlib]=1 [seaborn]=1  [plotly]=1  [spark]=1 
    [hadoop]=1 [rstudio]=1  [caret]=1  [root-framework]=1 
    [geant4]=1 [openfoam]=1  [lammps]=1  [quanrumespresso]=1 
    [gromacs]=1 [paraview]=1  [blender]=1  [simulation]=1 
    [stellarium]=1 [astropy]=1  [saoimageds9]=1  [celestia]=1 
    [sagemath]=1 [maxima]=1  [sympy]=1  [octave]=1 
    [R]=1 [jupyter-notebook]=1  [pspp]=1  [gretl]=1 
    [gnuplot]=1 [texmaker]=1  [lyx]=1  [texstudio]=1 
    [zotero]=1 


    )

    echo "Processing packages:"
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do

       if [[ -n "${base_packages[$pkg]}" ]]; then
            echo " - $pkg: installed in base system"
            sleep 1
        elif [[ -n "${non_ready_packages[$pkg]}" ]]; then
            echo " - $pkg: available in next release"
            sleep 0.2

        else 

        case "$pkg" in
    vscode)
        #chroot /home/kraken /bin/bash -c "kraken download vscode && kraken prepare vscode "
       
        
         #chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#vscode"
	       chroot /home/kraken /bin/bash -c "kraken entropy vscode"
        ;;
        
    ideaic)
         
       # chroot /home/kraken /bin/bash -c "kraken download ideaic && kraken prepare ideaic "

        chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#jetbrains.idea-community"

        ;;
        
    cli)
     #chroot /home/kraken /bin/bash -c "kraken download go && kraken prepare go && kraken install go " 
     #sleep 1
         #chroot /home/kraken /bin/bash -c "kraken download cli && kraken prepare cli && kraken build cli  && kraken install cli " 
       #chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#gh"
        chroot /home/kraken /bin/bash -c "kraken entropy cli"
        ;;
        
    gitlabcli)

    #chroot /home/kraken /bin/bash -c "kraken download go && kraken prepare go && kraken install go " 
    #sleep 1 
       # chroot /home/kraken /bin/bash -c "kraken download gitlabcli && kraken prepare gitlabcli && kraken build gitlabcli && kraken install gitlabcli  && kraken postinstall gitlabcli " 
       #chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#glab"
       chroot /home/kraken /bin/bash -c "kraken entropy gitlabcli"
        ;;
        
    valgrind)
        #chroot /home/kraken /bin/bash -c "kraken download valgrind && kraken prepare valgrind &&  kraken build valgrind && kraken install valgrind " 
        # chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#valgrind"
        chroot /home/kraken /bin/bash -c "kraken entropy valgrind"
        ;;
        
    java)
        #chroot /home/kraken /bin/bash -c "kraken download java && kraken prepare java &&  kraken install java && kraken postinstall java " 
        chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#jdk"
        ;;
        
    php)
        #chroot /home/kraken /bin/bash -c "kraken download apr  && kraken prepare apr && kraken build apr  &&  kraken install apr  "
        # sleep 1
        #chroot /home/kraken /bin/bash -c "kraken download apr-util && kraken prepare apr-util && kraken build apr-util &&  kraken install apr-util  "
        #sleep 1 

        #chroot /home/kraken /bin/bash -c "kraken download pcre2  && kraken prepare pcre2 && kraken build pcre2  &&  kraken install pcre2  "
      #sleep 1 

       # chroot /home/kraken /bin/bash -c "kraken download apache  && kraken prepare apache && kraken build apache  &&  kraken install apache  "
      #sleep 1 

      #chroot /home/kraken /bin/bash -c "kraken download icu  && kraken prepare icu && kraken build icu  &&  kraken install icu  "
      #sleep 1 

      #chroot /home/kraken /bin/bash -c "kraken download libxml2  && kraken prepare libxml2 && kraken build libxml2  &&  kraken install libxml2 && kraken postinstall libxml2  "
       #  sleep 1 


        # chroot /home/kraken /bin/bash -c "kraken download php  && kraken prepare php && kraken build php &&  kraken install php && kraken postinstall php "
        
        chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#php"
        ;;
        
    go)
        #chroot /home/kraken /bin/bash -c "kraken download go && kraken prepare go && kraken install go "
        #chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#go"
        chroot /home/kraken /bin/bash -c "kraken entropy go"
        ;;
        
    maven)
        
    
    #chroot /home/kraken /bin/bash -c "kraken download apache-maven && kraken prepare apache-maven && kraken build apache-maven &&  kraken install apache-maven "
       #chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#maven"
       chroot /home/kraken /bin/bash -c "kraken entropy apache-maven"
        ;;
        
    podman)
         #chroot /home/kraken /bin/bash -c "kraken download podman-remote && kraken prepare podman-remote"
       #chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#podman"
       chroot /home/kraken /bin/bash -c "kraken entropy podman-remote"
        ;;
        
    kubectl)
        #chroot /home/kraken /bin/bash -c "kraken download kubectl && kraken prepare kubectl"
        chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#kubectl"
        ;;
        
    terraform)
       
       
             #chroot /home/kraken /bin/bash -c "kraken download terraform && kraken prepare terraform "
            chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#terraform"
        ;;
        
    ansible)
       # chroot /home/kraken /bin/bash -c "kraken download ansible  && kraken prepare ansible &&  kraken install ansible  "
       # chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#ansible"
       chroot /home/kraken /bin/bash -c "kraken entropy ansible"
       
        ;;
        
    awscli)
        #chroot /home/kraken /bin/bash -c "kraken download awscli && kraken prepare awscli "
         chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#awscli2"
        
        ;;
        
    kotlin)
        
        
        #chroot /home/kraken /bin/bash -c "kraken download kotlin && kraken prepare kotlin "
        chroot /home/kraken /bin/bash -c "nix profile install nixpkgs#kotlin"
        
        ;;
        
    *)
        echo "Package not recognized: $pkg"
        ;;
esac

                                   
         
        sleep 0.5
        fi
    done
fi



echo "PROGRESS:100:Installation complete"
sleep 3

umount -R /home/kraken


fi






#case 2 --------------------------------------

if [ "$home_on" == "yes" ] && [ "$swap_on" == "no" ]; then
   echo "PROGRESS:0:Starting installation..."
    echo "Creating partitions with home (no swap)..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=25G, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=home" | sfdisk "$DISK"
    
    sleep 3
     echo "PROGRESS:25:Disk partitioned"
    echo "Formatting partitions..."
    mkfs.ext4 -F "${DISK}2"
    mkfs.ext4 -F  "${DISK}3"
    echo "Partitioning and formatting completed."
    
    echo "mounting root partition ..."
    mount "${DISK}2" /home/kraken


   
echo "PROGRESS:40:Prepare Files system"

sleep 5
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken

echo "PROGRESS:70:Configure Bootloader"
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
echo "PROGRESS:50:Packages installed"
echo "chroot to the new system "
chroot /home/kraken  /bin/bash << CHROOT_EOF

grub-install "$DISK"
sleep 3
cp -r /usr/share/grub/themes /boot/grub/
sleep 2
mkdir -p  /boot/grub/fonts
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_90.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_54.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_20.pf2 /boot/grub/fonts/

sleep 3 

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)
insmod vbe
set gfxmode=1024x768
insmod gfxterm
terminal_output gfxterm
insmod font
insmod efi_gop
insmod efi_uga
loadfont /boot/grub/fonts/dersu_uzala_brush_16.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_54.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_60.pf2
loadfont /boot/grub/fonts/fira_code_16.pf2
loadfont /boot/grub/fonts/fira_code_20.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_100.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_90.pf2

insmod png
set theme=/boot/grub/themes/kraken_grub_theme/theme.txt

if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}
menuentry "kraken os (Debug) " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}

menuentry "kraken os (Ram)" {
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
useradd -m -G wheel,input,audio,sddm,seat,tty,video,lpadmin "$username"
echo "$username:$userpass" | chpasswd
mount "${DISK}3" /home 
mkdir /home/"$username"
chown "$username":"$username" /home/"$username"

cp /root/.xinitrc /home/"$username"/
cp /root/.Xauthority /home/"$username"/


mkdir -pv "/home/$username/.config"
mkdir -pv "/home/$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config"
chown "$username":"$username" /home/"$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config/alacritty.toml"

cat > "/home/$username/.config/alacritty/alacritty.toml" << 'EOF'
[shell]
program = "bash"
args = ["-c", "fastfetch; exec bash"]
[window]
opacity=.9
EOF

/usr/bin/alacritty migrate


cp "/home/$username/.bashrc" "/home/$username/.bashrc.bak"

cat > "/home/$username/.bashrc" << 'EOF'
# Optimize build jobs
export MAKEFLAGS="-j$(nproc)"

# Custom prompt (color codes embedded directly in PS1)
if [[ $EUID == 0 ]]; then
    PS1="\[\e[1;31m\]\u [ \[\e[0m\]\w\[\e[1;31m\] ]# \[\e[0m\]"
else
    PS1="\[\e[1;32m\]\u [ \[\e[0m\]\w\[\e[1;32m\] ]\$ \[\e[0m\]"
fi


unset script


export WLR_NO_HARDWARE_CURSORS="1"  
export GDK_BACKEND="wayland"        
EOF
chown "$username":"$username" /home/"$username/.bashrc"
sleep 2 
umount -R "${DISK}3"




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
rm -Rf /etc/rc.d/init.d/startkde




    echo "PROGRESS:30:Selected packages"
echo -e "\nSelected Packages:"
if [ -n "$packages" ]; then
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do
        echo " - $pkg"
    done
else
    echo "No packages selected"
fi  


echo "PROGRESS:50:Packages installed"
if [ -n "$packages" ]; then

    declare -A base_packages=(
        [gcc]=1 [clang]=1 [rustc]=1 [llvm]=1 [gc]=1 
        [vim]=1 [cmake]=1 [ninja]=1 [meson]=1 [git]=1 
        [gdb]=1 [strace]=1 [python3]=1 [npm]=1 [pip]=1 
        [cargo]=1 [sqlite3]=1 [curl]=1 [wget]=1
    )

    declare -A non_ready_packages=(
   
    [composer]=1 [gin]=1  [restapi]=1  [jest]=1 
    [cypress]=1  [mariadb]=1 [docker]=1 [azurcli]=1  [googlecloudsdk]=1 
    [grafana]=1  [nagios]=1 [prometheus]=1 
    [react-nativeb]=1 [wireshark]=1
    [nmap]=1  [openvpn]=1 [netcat]=1 
    [wireguard]=1  [metasploit]=1 [burpsuite]=1 
    [jhontheripper]=1 [aircrack]=1  [hashcat]=1  [scikitlearn]=1 
    [tensorflow]=1 [pytorch]=1  [panda]=1  [numpy]=1 
    [matplotlib]=1 [seaborn]=1  [plotly]=1  [spark]=1 
    [hadoop]=1 [rstudio]=1  [caret]=1  [root-framework]=1 
    [geant4]=1 [openfoam]=1  [lammps]=1  [quanrumespresso]=1 
    [gromacs]=1 [paraview]=1  [blender]=1  [simulation]=1 
    [stellarium]=1 [astropy]=1  [saoimageds9]=1  [celestia]=1 
    [sagemath]=1 [maxima]=1  [sympy]=1  [octave]=1 
    [R]=1 [jupyter-notebook]=1  [pspp]=1  [gretl]=1 
    [gnuplot]=1 [texmaker]=1  [lyx]=1  [texstudio]=1 
    [zotero]=1 


    )

    echo "Processing packages:"
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do

       if [[ -n "${base_packages[$pkg]}" ]]; then
            echo " - $pkg: installed in base system"
            sleep 1
        elif [[ -n "${non_ready_packages[$pkg]}" ]]; then
            echo " - $pkg: available in next release"
            sleep 0.2

        else 

        case "$pkg" in
    vscode | emacs)
        /usr/bin/kraken entropy emacs
        ;;
        
    ideaic)
        /usr/bin/kraken entropy ideaic
        ;;
        
    cli)
        /usr/bin/kraken entropy cli
        ;;
        
    gitlabcli)
        /usr/bin/kraken entropy gitlabcli
        ;;
        
    valgrind)
        /usr/bin/kraken entropy valgrind
        ;;
        
    java)
        /usr/bin/kraken entropy java
        /usr/bin/kraken entropy giflib
        /usr/bin/kraken entropy libXt
        /usr/bin/kraken download jdk
        /usr/bin/kraken prepare jdk
        /usr/bin/kraken build jdk
        /usr/bin/kraken fakeinstall jdk
        /usr/bin/kraken install jdk
        /usr/bin/kraken postinstall jdk
        ;;
        
    php)
        /usr/bin/kraken entropy apache
        /usr/bin/kraken entropy libxml2
        /usr/bin/kraken download php
        /usr/bin/kraken prepare php
        /usr/bin/kraken build php
        /usr/bin/kraken fakeinstall php
        /usr/bin/kraken install php
        /usr/bin/kraken postinstall php
        ;;
        
    go)
        /usr/bin/kraken entropy go
        ;;
        
    maven)
        /usr/bin/kraken entropy apache-maven
        ;;
        
    podman)
        /usr/bin/kraken entropy podman-remote
        ;;
        
    kubectl)
        /usr/bin/kraken entropy kubectl
        ;;
        
    terraform)
        /usr/bin/kraken entropy terraform
        ;;
        
    ansible)
        /usr/bin/kraken download ansible
        /usr/bin/kraken prepare ansible
        /usr/bin/kraken build ansible
        /usr/bin/kraken fakeinstall ansible
        /usr/bin/kraken install ansible
        /usr/bin/kraken postinstall ansible
        ;;
        
    awscli)
        /usr/bin/kraken entropy awscli
        ;;
        
    kotlin)
        /usr/bin/kraken entropy kotlin
        ;;
        
    *)
        echo "Package not recognized: $pkg"
        ;;
esac

                                   
         
        sleep 0.5
    done
fi





CHROOT_EOF
echo "PROGRESS:100:Installation complete"
sleep 3

umount -R /home/kraken






fi










#case 3 -------------------------------------
if [ "$home_on" == "no" ] && [ "$swap_on" == "yes" ]; then
echo "PROGRESS:0:Starting installation..."
    echo "Creating partitions with swap (no home)..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=2G, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name=swap
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root" | sfdisk "$DISK"
    
    sleep 3
    echo "PROGRESS:25:Disk partitioned"
    echo "Formatting partitions..."
    mkswap "${DISK}2"
    mkfs.ext4 -F  "${DISK}3"
    echo "Partitioning and formatting completed."

    
    echo "mounting root partition ..."
    mount "${DISK}3" /home/kraken
echo "PROGRESS:40:Prepare Files system"
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
echo "PROGRESS:50:Packages installed"
echo "chroot to the new system "
chroot /home/kraken  /bin/bash << CHROOT_EOF

grub-install "$DISK"
 sleep 3 

 cp -r /usr/share/grub/themes /boot/grub/
sleep 2
mkdir -p  /boot/grub/fonts
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_90.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_54.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_20.pf2 /boot/grub/fonts/

sleep 3 

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)
insmod vbe
set gfxmode=1024x768
insmod gfxterm
terminal_output gfxterm
insmod font
insmod efi_gop
insmod efi_uga
loadfont /boot/grub/fonts/dersu_uzala_brush_16.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_54.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_60.pf2
loadfont /boot/grub/fonts/fira_code_16.pf2
loadfont /boot/grub/fonts/fira_code_20.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_100.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_90.pf2

insmod png
set theme=/boot/grub/themes/kraken_grub_theme/theme.txt

if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}3 ro
}
menuentry "kraken os (Debug) " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}3 ro
}

menuentry "kraken os (Ram)" {
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
useradd -m -G wheel,input,audio,sddm,seat,tty,video,lpadmin "$username"
echo "$username:$userpass" | chpasswd

mkdir /home/"$username"
chown "$username":"$username" /home/"$username"

cp /root/.xinitrc /home/"$username"/
cp /root/.Xauthority /home/"$username"/


mkdir -pv "/home/$username/.config"
mkdir -pv "/home/$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config"
chown "$username":"$username" /home/"$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config/alacritty.toml"

cat > "/home/$username/.config/alacritty/alacritty.toml" << 'EOF'
[shell]
program = "bash"
args = ["-c", "fastfetch; exec bash"]
EOF

/usr/bin/alacritty migrate


cp "/home/$username/.bashrc" "/home/$username/.bashrc.bak"

cat > "/home/$username/.bashrc" << 'EOF'
# Optimize build jobs
export MAKEFLAGS="-j$(nproc)"

# Custom prompt (color codes embedded directly in PS1)
if [[ $EUID == 0 ]]; then
    PS1="\[\e[1;31m\]\u [ \[\e[0m\]\w\[\e[1;31m\] ]# \[\e[0m\]"
else
    PS1="\[\e[1;32m\]\u [ \[\e[0m\]\w\[\e[1;32m\] ]\$ \[\e[0m\]"
fi


unset script


export WLR_NO_HARDWARE_CURSORS="1"  
export GDK_BACKEND="wayland"        
EOF
chown "$username":"$username" /home/"$username/.bashrc"
sleep 2 





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
rm -Rf /etc/rc.d/init.d/startkde


    echo "PROGRESS:30:Selected packages"
echo -e "\nSelected Packages:"
if [ -n "$packages" ]; then
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do
        echo " - $pkg"
    done
else
    echo "No packages selected"
fi  


echo "PROGRESS:50:Packages installed"
if [ -n "$packages" ]; then

    declare -A base_packages=(
        [gcc]=1 [clang]=1 [rustc]=1 [llvm]=1 [gc]=1 
        [vim]=1 [cmake]=1 [ninja]=1 [meson]=1 [git]=1 
        [gdb]=1 [strace]=1 [python3]=1 [npm]=1 [pip]=1 
        [cargo]=1 [sqlite3]=1 [curl]=1 [wget]=1
    )

    declare -A non_ready_packages=(
   
    [composer]=1 [gin]=1  [restapi]=1  [jest]=1 
    [cypress]=1  [mariadb]=1 [docker]=1 [azurcli]=1  [googlecloudsdk]=1 
    [grafana]=1  [nagios]=1 [prometheus]=1 
    [react-nativeb]=1 [wireshark]=1
    [nmap]=1  [openvpn]=1 [netcat]=1 
    [wireguard]=1  [metasploit]=1 [burpsuite]=1 
    [jhontheripper]=1 [aircrack]=1  [hashcat]=1  [scikitlearn]=1 
    [tensorflow]=1 [pytorch]=1  [panda]=1  [numpy]=1 
    [matplotlib]=1 [seaborn]=1  [plotly]=1  [spark]=1 
    [hadoop]=1 [rstudio]=1  [caret]=1  [root-framework]=1 
    [geant4]=1 [openfoam]=1  [lammps]=1  [quanrumespresso]=1 
    [gromacs]=1 [paraview]=1  [blender]=1  [simulation]=1 
    [stellarium]=1 [astropy]=1  [saoimageds9]=1  [celestia]=1 
    [sagemath]=1 [maxima]=1  [sympy]=1  [octave]=1 
    [R]=1 [jupyter-notebook]=1  [pspp]=1  [gretl]=1 
    [gnuplot]=1 [texmaker]=1  [lyx]=1  [texstudio]=1 
    [zotero]=1 


    )

    echo "Processing packages:"
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do

       if [[ -n "${base_packages[$pkg]}" ]]; then
            echo " - $pkg: installed in base system"
            sleep 1
        elif [[ -n "${non_ready_packages[$pkg]}" ]]; then
            echo " - $pkg: available in next release"
            sleep 0.2

        else 

        case "$pkg" in
    vscode | emacs)
        /usr/bin/kraken entropy emacs
        ;;
        
    ideaic)
        /usr/bin/kraken entropy ideaic
        ;;
        
    cli)
        /usr/bin/kraken entropy cli
        ;;
        
    gitlabcli)
        /usr/bin/kraken entropy gitlabcli
        ;;
        
    valgrind)
        /usr/bin/kraken entropy valgrind
        ;;
        
    java)
        /usr/bin/kraken entropy java
        /usr/bin/kraken entropy giflib
        /usr/bin/kraken entropy libXt
        /usr/bin/kraken download jdk
        /usr/bin/kraken prepare jdk
        /usr/bin/kraken build jdk
        /usr/bin/kraken fakeinstall jdk
        /usr/bin/kraken install jdk
        /usr/bin/kraken postinstall jdk
        ;;
        
    php)
        /usr/bin/kraken entropy apache
        /usr/bin/kraken entropy libxml2
        /usr/bin/kraken download php
        /usr/bin/kraken prepare php
        /usr/bin/kraken build php
        /usr/bin/kraken fakeinstall php
        /usr/bin/kraken install php
        /usr/bin/kraken postinstall php
        ;;
        
    go)
        /usr/bin/kraken entropy go
        ;;
        
    maven)
        /usr/bin/kraken entropy apache-maven
        ;;
        
    podman)
        /usr/bin/kraken entropy podman-remote
        ;;
        
    kubectl)
        /usr/bin/kraken entropy kubectl
        ;;
        
    terraform)
        /usr/bin/kraken entropy terraform
        ;;
        
    ansible)
        /usr/bin/kraken download ansible
        /usr/bin/kraken prepare ansible
        /usr/bin/kraken build ansible
        /usr/bin/kraken fakeinstall ansible
        /usr/bin/kraken install ansible
        /usr/bin/kraken postinstall ansible
        ;;
        
    awscli)
        /usr/bin/kraken entropy awscli
        ;;
        
    kotlin)
        /usr/bin/kraken entropy kotlin
        ;;
        
    *)
        echo "Package not recognized: $pkg"
        ;;
esac

                                   
         
        sleep 0.5
    done
fi





CHROOT_EOF
echo "PROGRESS:100:Installation complete"
sleep 3

umount -R /home/kraken

fi




#case 4 -------------------------
if [ "$home_on" == "no" ] && [ "$swap_on" == "no" ]; then
echo "PROGRESS:0:Starting installation..."
    echo "Creating partitions without swap or home..."
    echo "label: gpt
size=500M, type=21686148-6449-6E6F-744E-656564454649, name=bios_boot
size=-, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=root" | sfdisk "$DISK"
    
    sleep 3
    echo "PROGRESS:25:Disk partitioned"
    echo "Formatting partitions..."
    mkfs.ext4 -F  "${DISK}2"  
    echo "Partitioning and formatting completed."


    echo "mounting root partition ..."
   # echo "mounting root partition ..."
    mount "${DISK}2" /home/kraken


echo "PROGRESS:40:Prepare Files system"
sleep 5
rsync -av --exclude={"/dev/*","/proc/*","/mnt/*","/home/*","/media/*","/run/*","/sys/*","/boot/*"} / /home/kraken

echo "PROGRESS:70:Configure Bootloader"
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
echo "PROGRESS:50:Packages installed"
echo "chroot to the new system "
chroot /home/kraken  /bin/bash << CHROOT_EOF

grub-install "$DISK"
sleep 3 

cp -r /usr/share/grub/themes /boot/grub/
sleep 2
mkdir -p  /boot/grub/fonts
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_90.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_16.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/dersu_uzala_brush_54.pf2 /boot/grub/fonts/
cp /boot/grub/themes/kraken_grub_theme/fira_code_20.pf2 /boot/grub/fonts/

sleep 3

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
# el dinary mara men houna
set default=0
set timeout=10

insmod part_gpt
insmod ext2
set root=(hd0,2)
insmod vbe
set gfxmode=1024x768
insmod gfxterm
terminal_output gfxterm
insmod font
insmod efi_gop
insmod efi_uga
loadfont /boot/grub/fonts/dersu_uzala_brush_16.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_54.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_60.pf2
loadfont /boot/grub/fonts/fira_code_16.pf2
loadfont /boot/grub/fonts/fira_code_20.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_100.pf2
loadfont /boot/grub/fonts/dersu_uzala_brush_90.pf2

insmod png
set theme=/boot/grub/themes/kraken_grub_theme/theme.txt

if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, kraken os " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}
menuentry "kraken os (Debug) " {
  linux  /boot/vmlinuz-6.10.5-kraken-1.0 root=${DISK}2 ro
}

menuentry "kraken os (Ram)" {
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
useradd -m -G wheel,input,audio,sddm,seat,tty,video,lpadmin "$username"
echo "$username:$userpass" | chpasswd

mkdir /home/"$username"
chown "$username":"$username" /home/"$username"

cp /root/.xinitrc /home/"$username"/
cp /root/.Xauthority /home/"$username"/


mkdir -pv "/home/$username/.config"
mkdir -pv "/home/$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config"
chown "$username":"$username" /home/"$username/.config/alacritty"
chown "$username":"$username" /home/"$username/.config/alacritty.toml"

cat > "/home/$username/.config/alacritty/alacritty.toml" << 'EOF'
[shell]
program = "bash"
args = ["-c", "fastfetch; exec bash"]
EOF

/usr/bin/alacritty migrate


cp "/home/$username/.bashrc" "/home/$username/.bashrc.bak"

cat > "/home/$username/.bashrc" << 'EOF'
# Optimize build jobs
export MAKEFLAGS="-j$(nproc)"

# Custom prompt (color codes embedded directly in PS1)
if [[ $EUID == 0 ]]; then
    PS1="\[\e[1;31m\]\u [ \[\e[0m\]\w\[\e[1;31m\] ]# \[\e[0m\]"
else
    PS1="\[\e[1;32m\]\u [ \[\e[0m\]\w\[\e[1;32m\] ]\$ \[\e[0m\]"
fi


unset script


export WLR_NO_HARDWARE_CURSORS="1"  
export GDK_BACKEND="wayland"        
EOF
chown "$username":"$username" /home/"$username/.bashrc"
sleep 2 





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
rm -Rf /etc/rc.d/init.d/startkde




    echo "PROGRESS:30:Selected packages"
echo -e "\nSelected Packages:"
if [ -n "$packages" ]; then
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do
        echo " - $pkg"
    done
else
    echo "No packages selected"
fi  


echo "PROGRESS:50:Packages installed"
if [ -n "$packages" ]; then

    declare -A base_packages=(
        [gcc]=1 [clang]=1 [rustc]=1 [llvm]=1 [gc]=1 
        [vim]=1 [cmake]=1 [ninja]=1 [meson]=1 [git]=1 
        [gdb]=1 [strace]=1 [python3]=1 [npm]=1 [pip]=1 
        [cargo]=1 [sqlite3]=1 [curl]=1 [wget]=1
    )

    declare -A non_ready_packages=(
   
    [composer]=1 [gin]=1  [restapi]=1  [jest]=1 
    [cypress]=1  [mariadb]=1 [docker]=1 [azurcli]=1  [googlecloudsdk]=1 
    [grafana]=1  [nagios]=1 [prometheus]=1 
    [react-nativeb]=1 [wireshark]=1
    [nmap]=1  [openvpn]=1 [netcat]=1 
    [wireguard]=1  [metasploit]=1 [burpsuite]=1 
    [jhontheripper]=1 [aircrack]=1  [hashcat]=1  [scikitlearn]=1 
    [tensorflow]=1 [pytorch]=1  [panda]=1  [numpy]=1 
    [matplotlib]=1 [seaborn]=1  [plotly]=1  [spark]=1 
    [hadoop]=1 [rstudio]=1  [caret]=1  [root-framework]=1 
    [geant4]=1 [openfoam]=1  [lammps]=1  [quanrumespresso]=1 
    [gromacs]=1 [paraview]=1  [blender]=1  [simulation]=1 
    [stellarium]=1 [astropy]=1  [saoimageds9]=1  [celestia]=1 
    [sagemath]=1 [maxima]=1  [sympy]=1  [octave]=1 
    [R]=1 [jupyter-notebook]=1  [pspp]=1  [gretl]=1 
    [gnuplot]=1 [texmaker]=1  [lyx]=1  [texstudio]=1 
    [zotero]=1 


    )

    echo "Processing packages:"
    IFS=',' read -ra PKG_ARRAY <<< "$packages"
    for pkg in "${PKG_ARRAY[@]}"; do

       if [[ -n "${base_packages[$pkg]}" ]]; then
            echo " - $pkg: installed in base system"
            sleep 1
        elif [[ -n "${non_ready_packages[$pkg]}" ]]; then
            echo " - $pkg: available in next release"
            sleep 0.2

        else 

        case "$pkg" in
    vscode | emacs)
        /usr/bin/kraken entropy emacs
        ;;
        
    ideaic)
        /usr/bin/kraken entropy ideaic
        ;;
        
    cli)
        /usr/bin/kraken entropy cli
        ;;
        
    gitlabcli)
        /usr/bin/kraken entropy gitlabcli
        ;;
        
    valgrind)
        /usr/bin/kraken entropy valgrind
        ;;
        
    java)
        /usr/bin/kraken entropy java
        /usr/bin/kraken entropy giflib
        /usr/bin/kraken entropy libXt
        /usr/bin/kraken download jdk
        /usr/bin/kraken prepare jdk
        /usr/bin/kraken build jdk
        /usr/bin/kraken fakeinstall jdk
        /usr/bin/kraken install jdk
        /usr/bin/kraken postinstall jdk
        ;;
        
    php)
        /usr/bin/kraken entropy apache
        /usr/bin/kraken entropy libxml2
        /usr/bin/kraken download php
        /usr/bin/kraken prepare php
        /usr/bin/kraken build php
        /usr/bin/kraken fakeinstall php
        /usr/bin/kraken install php
        /usr/bin/kraken postinstall php
        ;;
        
    go)
        /usr/bin/kraken entropy go
        ;;
        
    maven)
        /usr/bin/kraken entropy apache-maven
        ;;
        
    podman)
        /usr/bin/kraken entropy podman-remote
        ;;
        
    kubectl)
        /usr/bin/kraken entropy kubectl
        ;;
        
    terraform)
        /usr/bin/kraken entropy terraform
        ;;
        
    ansible)
        /usr/bin/kraken download ansible
        /usr/bin/kraken prepare ansible
        /usr/bin/kraken build ansible
        /usr/bin/kraken fakeinstall ansible
        /usr/bin/kraken install ansible
        /usr/bin/kraken postinstall ansible
        ;;
        
    awscli)
        /usr/bin/kraken entropy awscli
        ;;
        
    kotlin)
        /usr/bin/kraken entropy kotlin
        ;;
        
    *)
        echo "Package not recognized: $pkg"
        ;;
esac

                                   
         
        sleep 0.5
    done
fi










CHROOT_EOF
echo "PROGRESS:100:Installation complete"
sleep 3

umount -R /home/kraken


fi


echo -e "\033[34m installation done successfully .\033[0m"

exit 0
