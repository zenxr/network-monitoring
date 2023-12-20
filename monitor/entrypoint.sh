#!/bin/sh

# start cron
echo "Starting cron process"
/usr/sbin/crond -f -l 8 -L /dev/stdout
