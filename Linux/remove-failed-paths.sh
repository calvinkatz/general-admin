#!/bin/bash

# Rescan HBAs
for i in /sys/class/scsi_host/host*/scan
  do echo "- - -" > $i
done

DEV=`multipath -ll | grep failed | awk '{print $3}'`

# Remove failed paths
for i in $DEV
  do echo 1 > /sys/block/${i}/device/delete
done
