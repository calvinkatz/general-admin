#!/bin/bash

# Setup CentOS7 Template

# Update VM
yum makecache
yum update -y

# Install EPEL and other pre-requisites
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum makecache
yum install -y htop tmux open-vm-tools perl chrony
    
# Setup Chrony
cp /etc/chrony.conf /etc/chrony.conf.bak
cat <<EOF > /etc/chrony.conf
server <server> iburst
server <server> iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
systemctl enable chronyd
