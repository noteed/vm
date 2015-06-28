#! /bin/bash

# This build a ISO file suitable for unattended install.
# Based on https://github.com/netson/ubuntu-unattended.

# Place to store the final iso file, a.k.a. this directory.
tmp="/home/thu/projects/vm"
hostname="ubuntu"
domain="ubuntu"

download_file="ubuntu-14.04.2-server-amd64.iso"           # filename of the iso to be downloaded
download_location="http://releases.ubuntu.com/14.04/"     # location of the file to be downloaded
new_iso_name="ubuntu-14.04.2-server-amd64-unattended.iso" # filename of the new iso file to be created

timezone="UTC"
username="horde"
password="horde"

# define spinner function for slow tasks
# courtesy of http://fitnr.com/showing-a-bash-spinner.html
spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# define download function
# courtesy of http://fitnr.com/showing-file-download-progress-using-wget.html
download()
{
    local url=$1
    echo -n "    "
    wget --progress=dot $url 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    echo -ne "\b\b\b\b"
    echo " DONE"
}

# define function to check if program is installed
# courtesy of https://gist.github.com/JamieMason/4761049
function program_is_installed {
    # set to 1 initially
    local return_=1
    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }
    # return value
    echo $return_
}

# download the ubunto iso
cd $tmp
if [[ ! -f $tmp/$download_file ]]; then
    echo -n " downloading $download_file: "
    download "$download_location$download_file"
fi

# install required packages
echo " installing required packages"
if [ $(program_is_installed "mkpasswd") -eq 0 ] || [ $(program_is_installed "mkisofs") -eq 0 ]; then
    (apt-get -y update > /dev/null 2>&1) &
    spinner $!
    (apt-get -y install whois genisoimage > /dev/null 2>&1) &
    spinner $!
fi

# create working folders
echo " remastering your iso file"
mkdir -p $tmp
mkdir -p $tmp/iso_org
mkdir -p $tmp/iso_new

# mount the image
if grep -qs $tmp/iso_org /proc/mounts ; then
    echo " image is already mounted, continue"
else
    (mount -o loop $tmp/$download_file $tmp/iso_org > /dev/null 2>&1)
fi

# copy the iso contents to the working directory
(cp -rT $tmp/iso_org $tmp/iso_new > /dev/null 2>&1) &
spinner $!

# set the language for the installation menu
cd $tmp/iso_new
echo en > $tmp/iso_new/isolinux/lang

# set late command
late_command="cp /cdrom/provision.sh /target/usr/bin/ ; cp /cdrom/edit-sudoers.sh /target/usr/bin/ ; cp -a /cdrom/etc-tinc /target/etc/tinc ; cp /cdrom/setup-docker-tinc.sh /target/usr/bin/ ; in-target /usr/bin/provision.sh ; rm /target/usr/bin/provision.sh ; rm /target/usr/bin/edit-sudoers.sh"

# copy the seed file to the iso
cp $tmp/seed.seed $tmp/iso_new/preseed/
cp $tmp/provision.sh $tmp/iso_new/
cp $tmp/edit-sudoers.sh $tmp/iso_new/
cp $tmp/setup-docker-tinc.sh $tmp/iso_new/
cp -a $tmp/etc-tinc $tmp/iso_new/etc-tinc

# include firstrun script
echo "
# setup firstrun script
d-i preseed/late_command                                    string      $late_command" >> $tmp/iso_new/preseed/seed.seed

# generate the password hash
pwhash=$(echo $password | mkpasswd -s -m sha-512)

# update the seed file to reflect the users' choices
# the normal separator for sed is /, but both the password and the timezone may contain it
# so instead, I am using @
sed -i "s@{{username}}@$username@g" $tmp/iso_new/preseed/seed.seed
sed -i "s@{{pwhash}}@$pwhash@g" $tmp/iso_new/preseed/seed.seed
sed -i "s@{{hostname}}@$hostname@g" $tmp/iso_new/preseed/seed.seed
sed -i "s@{{domain}}@$domain@g" $tmp/iso_new/preseed/seed.seed
sed -i "s@{{timezone}}@$timezone@g" $tmp/iso_new/preseed/seed.seed

# calculate checksum for seed file
seed_checksum=$(md5sum $tmp/iso_new/preseed/seed.seed)

# add the autoinstall option to the menu
sed -i "/label install/ilabel autoinstall\n\
  menu label ^Autoinstall Ubuntu Server\n\
  kernel /install/vmlinuz\n\
  append file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz auto=true priority=high console=ttyS0 preseed/file=/cdrom/preseed/seed.seed preseed/file/checksum=$seed_checksum --" $tmp/iso_new/isolinux/txt.cfg

echo " creating the remastered iso"
cat $tmp/iso_new/isolinux/txt.cfg
sed -i 's/timeout 0/timeout 1/' $tmp/iso_new/isolinux/isolinux.cfg
sed -i 's/ui gfxboot bootlogo//' $tmp/iso_new/isolinux/isolinux.cfg
cd $tmp/iso_new
(mkisofs -D -r -V "UBUNTU_SERVER" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $tmp/$new_iso_name . > /dev/null 2>&1) &
spinner $!

# cleanup
umount $tmp/iso_org
rm -rf $tmp/iso_new
rm -rf $tmp/iso_org

# print info to user  
echo " finished remastering your ubuntu iso file"
echo " the new file is located at: $tmp/$new_iso_name"
echo

# unset vars
unset username
unset password
unset hostname
unset domain
unset timezone
unset pwhash
unset download_file
unset download_location
unset new_iso_name
unset tmp
unset seed_file
