#!/bin/bash
# https://kb.vmware.com/s/article/71264
# Set 'manual_cache_clean: True' in /etc/cloud/cloud.cfg

# Setup cloud-init
yum install -y cloud-init
cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak
echo "Modify cloud config now (/etc/cloud/cloud.cfg)"
echo "Press Enter to continue..."
read TEMP

echo "touch /etc/cloud/cloud-init.disabled" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

#cat <<EOF > /etc/cloud/cloud.cfg.d/99-custom-networking.cfg
#network: {config: disabled}
#EOF

# Cleanup yum cache
yum clean all

# Remove this file and state
rm ~/centos-prep-vm.sh
rm ~/anaconda-ks.cfg

# Clean and shutdown
cloud-init clean
shutdown -h -t 5sec
