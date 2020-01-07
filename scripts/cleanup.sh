#!/bin/bash
set +e

echo "[INFO] Cleaning up build files"
/bin/rm -rf /root/anaconda-ks.cfg
/bin/rm -rf /root/*cfg
/bin/rm -rf /var/log/anaconda
/bin/rm -f /root/.bash_history
/bin/rm -rf /root/*.iso 2>/dev/null

echo "[INFO] Cleaning up /tmp directory"
for x in $( ls -1A /tmp)
do
  /bin/rm -rf /tmp/$x 2>/dev/null
done

echo "[INFO] Cleaning up some misc log files"
MISC_FILES="rm* *-20* *.gz *[0-9]"
for x in $MISC_FILES
do
  find /var/log -type f -name "$x" -delete
done

echo "[INFO] truncating log files"
find /var/log -type f -exec truncate --size 0 {} \;

echo '[INFO] cleaning up SSH host keys'
rm -f /etc/ssh/ssh_host_*

echo "[INFO] Cleaning up yum cache of metadata and packages to save space"
yum -y clean all

echo "[INFO] Cleaning /var/cache/yum"
rm -rf /var/cache/yum

echo '[INFO] cleaning up machine-id'
cat > /etc/machine-id < /dev/null

echo '[INFO] cleaningl /var/lib/puppet/ssl'
rm -rf /var/lib/puppet/ssl

echo "[INFO] cleaning up any facters"
/bin/rm -rf /etc/facter 2>/dev/null

echo '[INFO] Recording box config date'
date > /etc/box_build_time

echo "==> Cleaning up temporary network addresses"
# Make sure udev doesn't block our network
# http://6.ptmc.org/?p=1649
if grep -q -i "release 6" /etc/redhat-release ; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules

    for ndev in `ls -1 /etc/sysconfig/network-scripts/ifcfg-*`; do
    if [ "`basename $ndev`" != "ifcfg-lo" ]; then
        sed -i '/^HWADDR/d' "$ndev";
        sed -i '/^UUID/d' "$ndev";
    fi
    done
fi
# Better fix that persists package updates: http://serverfault.com/a/485689
touch /etc/udev/rules.d/75-persistent-net-generator.rules
for ndev in `ls -1 /etc/sysconfig/network-scripts/ifcfg-*`; do
    if [ "`basename $ndev`" != "ifcfg-lo" ]; then
        sed -i '/^HWADDR/d' "$ndev";
        sed -i '/^UUID/d' "$ndev";
    fi
done
rm -rf /dev/.udev/

DISK_USAGE_BEFORE_CLEANUP=$(df -h)

if [[ $CLEANUP_BUILD_TOOLS  =~ true || $CLEANUP_BUILD_TOOLS =~ 1 || $CLEANUP_BUILD_TOOLS =~ yes ]]; then
    echo "==> Removing tools used to build virtual machine drivers"
    yum -y remove gcc libmpc mpfr cpp kernel-ml-devel kernel-ml-headers
fi

echo "==> Clean up yum cache of metadata and packages to save space"
yum -y --enablerepo='*' clean all

echo "==> Rebuild RPM DB"
rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

# delete any logs that have built up during the install
find /var/log/ -name *.log -exec rm -f {} \;

echo '==> Clear out swap and disable until reboot'
set +e
swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
case "$?" in
	2|0) ;;
	*) exit 1 ;;
esac
set -e
if [ "x${swapuuid}" != "x" ]; then
    # Whiteout the swap partition to reduce box size
    # Swap is disabled till reboot
    swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
    /sbin/swapoff "${swappart}"
    dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
    /sbin/mkswap -U "${swapuuid}" "${swappart}"
fi

echo '==> Zeroing out empty area to save space in the final image'
# Zero out the free space to save space in the final image.  Contiguous
# zeroed space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY

# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
sync

echo "==> Disk usage before cleanup"
echo "${DISK_USAGE_BEFORE_CLEANUP}"

echo "==> Disk usage after cleanup"
df -h
