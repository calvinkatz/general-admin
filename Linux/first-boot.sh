#!/bin/bash
# First boot script
# Post config for CentOS on VMware

# Disable cloud-init
touch /etc/cloud/cloud-init.disabled

# Remove this script
sed '/first-boot\.sh/d' file
rm /opt/first-boot.sh
