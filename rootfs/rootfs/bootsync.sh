#!/bin/sh

# Load TCE extensions
/etc/rc.d/tce-loader

# Automount a hard drive
/etc/rc.d/automount

mkdir -p /var/lib/boot2docker/log

#import settings from profile (NTP_SERVER)
test -f "/var/lib/boot2docker/profile" && . "/var/lib/boot2docker/profile"


# set the hostname
/etc/rc.d/hostname

# sync the clock (in the background, it takes 40s to timeout)
/etc/rc.d/ntpclient > /var/lib/boot2docker/log/ntpclient.log 2>&1 &

# TODO: move this (and the docker user creation&pwd out to its own over-rideable?))
if grep -q '^docker:' /etc/passwd; then
  # if we have the docker user, let's create the docker group
  /bin/addgroup -S docker
  # ... and add our docker user to it!
  /bin/addgroup docker docker
  # install public key for ssh
  (umask 077; mkdir -p /home/docker/.ssh/; echo "ssh-dss AAAAB3NzaC1kc3MAAACBAKOzm2qIAw8GhEX2NSHK0bV1XAPFUof1Ta2eY4K8jJntFVitvDceo/XIZ2Ga5r0MqkTEmpOUir/GixaoB5FkMeb23SYVPWhb58nK18XUsV426MN04hp0T5SH6AqpJB5/QNdt0VFzsl2sbkUuuKKFvav8+atg2oBmF+dd8BnphmBxAAAAFQDJQQmXZQQjnJZyxKU1ljqA3bmIeQAAAIEAndobYS0psm3rkm3j0LdDe/W8j8RMnTjT0/pciMWTanQhY7MiItI8jjMxKRaX1sLAVzKEQ3g2CT5NKYixqaWF4Kmwzq0SZ4fGEGcG9Xtr3kiNPKIoEb7aTB4xBql6GkG9Kewfv9alc0/EuF9k2r6rq+Nls9C9niWGoQDs6KVKEhUAAACAAv8Px1V4tCJwPxnge+PTddeRNhD0Lwd6OpaKMo55u3qxpM+77M8q84UpaNaX3dyKOHEVvoh4DvLEnAr9cPbZDG/pC39dsw8kOS/88sR+WGyu1hc05vyUBa8g4DSLDLFodM9KOOr33xpzISRYp0y6eyWCDlu+JE7+0kOBWMqqVic= docker@localhost" > /home/docker/.ssh/authorized_keys; sudo chown -R docker:docker /home/docker/.ssh/)
fi

# Configure SSHD
/etc/rc.d/sshd

# Launch ACPId
/etc/rc.d/acpid

# Launch Docker
/etc/rc.d/docker

# Allow local HD customisation
if [ -e /var/lib/boot2docker/bootlocal.sh ]; then
    /var/lib/boot2docker/bootlocal.sh &
fi
