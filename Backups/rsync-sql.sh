#!/bin/bash

# Sync SQL backups in the last 24 hours to target location.

# Source directory to copy files from
SRC_DIR='/mnt/repository/sql'

TARGET_HOST=target.domain.com

# Log, PID, and Socket dir
LOG=/var/log/rsync/rsync-sql.log
PID=/var/run/rsync-sql.pid
SOCK=/var/run/rsync-sql.sock

# SSH options for rsync
SSH_OPTS="ssh -S $SOCK -T -c aes128-gcm@openssh.com -o Compression=no -x"

function get_date ()
{
   echo $(date '+%d/%m/%Y %H:%M:%S');
}

if [ ! -f $PID ]; then
    echo "[$( get_date )] SQL Sync: STARTED" >> $LOG
    touch $PID    

    # Establish master control session
    echo "[$( get_date )] SQL Sync: Establishing SSH master control session" >> $LOG
    ssh -f -M -S $SOCK -T -c aes128-gcm@openssh.com -o Compression=no -o ControlPersist=60 -x root@$TARGET_HOST sleep 3600
    echo "[$( get_date )] SQL Sync: SSH master control session established" >> $LOG

    # For each sync file spawn rsync
    echo "[$( get_date )] SQL Sync: Begin sync" >> $LOG
    find $SRC_DIR -mtime 0 -type f -print0 | xargs -0 -I file -P 10 rsync -avR -e "$SSH_OPTS" file root@$TARGET_HOST:/
    echo "[$( get_date )] SQL Sync: Sync completed" >> $LOG

    # End master control session
    echo "[$( get_date )] SQL Sync: Ending SSH master control session" >> $LOG
    ssh -O stop -S $SOCK $TARGET_HOST
    echo "[$( get_date )] SQL Sync: SSH master control session ended" >> $LOG

    rm -f $PID
    echo "[$( get_date )] SQL Sync: ENDED" >> $LOG
else
    echo "[$( get_date )] Sync in progress, skipping..." >> $LOG
fi
