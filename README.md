# amavis
A lean alpine docker for Amavis, which automatically sets up a chroot environment on start.

Configure with postconf, or bind mount config from the host into /etc/amavisd.conf.

For logging, bind mount /dev/log:/dev/log and /dev/log:/var/amavis/dev/log.
