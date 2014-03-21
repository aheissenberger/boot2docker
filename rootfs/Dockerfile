FROM boot2docker/boot2docker:base
MAINTAINER Steeve Morin "steeve.morin@gmail.com"

ENV ROOTFS          /rootfs
ENV TCL_REPO_BASE   http://tinycorelinux.net/5.x/x86
ENV TCZ_DEPS        iptables \
                    iproute2 \
                    openssh openssl-1.0.0 \
                    tar \
                    gcc_libs \
                    acpid \
                    bash \
                    ncurses-common ncurses-terminfo ncurses ncurses-utils \
                    xz liblzma \
                    git expat2 libiconv libidn libgpg-error libgcrypt libssh2 \
                    nfs-utils tcp_wrappers portmap rpcbind libtirpc \
                    curl ntpclient

RUN apt-get -y install  squashfs-tools \
                        genisoimage \
                        xorriso \
                        syslinux \
                        automake \
                        module-init-tools \
                        pkg-config

# Make the ROOTFS
RUN mkdir -p $ROOTFS

# Install the kernel modules in $ROOTFS
RUN cd /linux-kernel && \
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install

# Remove useless kernel modules, based on unclejack/debian2docker
RUN cd $ROOTFS/lib/modules && \
    rm -rf ./*/kernel/sound/* && \
    rm -rf ./*/kernel/drivers/gpu/* && \
    rm -rf ./*/kernel/drivers/infiniband/* && \
    rm -rf ./*/kernel/drivers/isdn/* && \
    rm -rf ./*/kernel/drivers/media/* && \
    rm -rf ./*/kernel/drivers/staging/lustre/* && \
    rm -rf ./*/kernel/drivers/staging/comedi/* && \
    rm -rf ./*/kernel/fs/ocfs2/* && \
    rm -rf ./*/kernel/net/bluetooth/* && \
    rm -rf ./*/kernel/net/mac80211/* && \
    rm -rf ./*/kernel/net/sunrpc/* && \
    rm -rf ./*/kernel/net/wireless/*

# Install libcap
RUN curl -L ftp://ftp.de.debian.org/debian/pool/main/libc/libcap2/libcap2_2.22.orig.tar.gz | tar -C / -xz && \
    cd /libcap-2.22 && \
    sed -i 's/LIBATTR := yes/LIBATTR := no/' Make.Rules && \
    sed -i 's/\(^CFLAGS := .*\)/\1 -m32/' Make.Rules && \
    make && \
    mkdir -p output && \
    make prefix=`pwd`/output install && \
    mkdir -p $ROOTFS/usr/local/lib && \
    cp -av `pwd`/output/lib64/* $ROOTFS/usr/local/lib

ADD lxc-0.8.0-boot2docker.patch /

# Download LXC, patch it with a 0.8.0 port of @sebp's patch to properly change root from a ramdisk, compile and install
# Based on https://github.com/spahl/lxc/commit/d6b2904d50cac7c44e6f490308b8dd1417281529
RUN curl -L https://github.com/lxc/lxc/archive/lxc-0.8.0.tar.gz | tar -C / -xz && \
    cd /lxc-lxc-0.8.0 && \
    patch -p2 < /lxc-0.8.0-boot2docker.patch && \
    ./autogen.sh && \
    LIBCAPLIB=/libcap-2.22/output/ CFLAGS="-m32 -I${LIBCAPLIB}/include -L${LIBCAPLIB}/lib64" ./configure prefix=/usr/local --disable-apparmor --disable-bash && \
    make && \
    make prefix=$ROOTFS install && \
    mkdir -p $ROOTFS/usr/var/lib/lxc && \
    mkdir -p $ROOTFS/usr/local/lib/lxc/rootfs && \
    mkdir -p $ROOTFS/cgroup && \
    mkdir -p $ROOTFS/dev/mqueue

# Make sure the kernel headers are installed for aufs-util, and then build it
RUN cd /linux-kernel && \
    make INSTALL_HDR_PATH=/tmp/kheaders headers_install && \
    cd / && \
    git clone git://git.code.sf.net/p/aufs/aufs-util && \
    cd /aufs-util && \
    git checkout aufs3.9 && \
    CPPFLAGS="-m32 -I/tmp/kheaders/include" CLFAGS=$CPPFLAGS LDFLAGS=$CPPFLAGS make && \
    DESTDIR=$ROOTFS make install

# create and add virtualbox guest modules
ADD VBoxLinuxAdditions.run /
RUN export KERNEL=$( uname -r ) && \
    mkdir -p /lib/modules/${KERNEL} && \
    ln -s /linux-kernel /lib/modules/${KERNEL}/build && \
    chmod +x /VBoxLinuxAdditions.run && \
    sh "/VBoxLinuxAdditions.run"
# || echo "failed ME"
RUN  export DEFAULT_FILE_NAMES=" \
    /usr/bin/vboxadd-xclient \
    /usr/bin/VBoxClient \
    /usr/bin/VBoxControl \
    /usr/sbin/vbox-greeter \
    /usr/sbin/vboxadd-timesync \
    /usr/sbin/vboxadd-service \
    /usr/sbin/VBoxService \
    /sbin/mount.vboxsf \
    /usr/lib/VBoxOGLarrayspu.so \
    /usr/lib64/VBoxOGLarrayspu.so \
    /usr/lib/VBoxOGLcrutil.so \
    /usr/lib64/VBoxOGLcrutil.so \
    /usr/lib/VBoxOGLerrorspu.so \
    /usr/lib64/VBoxOGLerrorspu.so \
    /usr/lib/VBoxOGLfeedbackspu.so \
    /usr/lib64/VBoxOGLfeedbackspu.so \
    /usr/lib/VBoxOGLpackspu.so \
    /usr/lib64/VBoxOGLpackspu.so \
    /usr/lib/VBoxOGLpassthroughspu.so \
    /usr/lib64/VBoxOGLpassthroughspu.so \
    /usr/lib/VBoxOGL.so \
    /usr/lib64/VBoxOGL.so \
    /usr/share/xgreeters/vbox-greeter.desktop \
    /etc/X11/Xsession.d/98vboxadd-xclient \
    /etc/X11/xinit.d/98vboxadd-xclient \
    /etc/X11/xinit/xinitrc.d/98vboxadd-xclient.sh \
    /usr/bin/VBoxRandR \
    /usr/bin/VBoxClient-all \
    /etc/xdg/autostart/vboxclient.desktop \
    /usr/share/autostart/vboxclient.desktop \
    /etc/udev/rules.d/60-vboxadd.rules \
    /usr/share/xserver-xorg/pci/vboxvideo.ids \
    /etc/hal/fdi/policy/90-vboxguest.fdi \
    /etc/udev/rules.d/70-xorg-vboxmouse.rules \
    /usr/share/hal/fdi/policy/20thirdparty/90-vboxguest.fdi \
    /usr/lib/X11/xorg.conf.d/50-vboxmouse.conf \
    /usr/share/X11/xorg.conf.d/50-vboxmouse.conf \
    /usr/lib/dri/vboxvideo_dri.so \
    /usr/lib64/dri/vboxvideo_dri.so \
    /usr/lib64/xorg/modules/drivers/vboxvideo_drv.so \
    /usr/lib/xorg/modules/drivers/vboxvideo_drv.so \
    /usr/X11R6/lib64/modules/drivers/vboxvideo_drv.so \
    /usr/X11R6/lib/modules/drivers/vboxvideo_drv.so \
    /usr/X11R6/lib/X11/modules/drivers/vboxvideo_drv.so \
    /usr/lib64/xorg/modules/input/vboxmouse_drv.so \
    /usr/lib/xorg/modules/input/vboxmouse_drv.so \
    /usr/X11R6/lib64/modules/input/vboxmouse_drv.so \
    /usr/X11R6/lib/modules/input/vboxmouse_drv.so \
    /usr/X11R6/lib/X11/modules/input/vboxmouse_drv.so" && \
    for i in $DEFAULT_FILE_NAMES; do test -e "$i" && echo "F:$i"; done ; echo "OK"




# Download the rootfs, don't unpack it though:
RUN curl -L -o /tcl_rootfs.gz $TCL_REPO_BASE/release/distribution_files/rootfs.gz

# Install the TCZ dependencies
RUN for dep in $TCZ_DEPS; do \
        curl -L -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        unsquashfs -f -d $ROOTFS /tmp/$dep.tcz && \
        rm -f /tmp/$dep.tcz ;\
    done

ADD isolinux /isolinux
ADD make_iso.sh /

# Copy over out custom rootfs
ADD rootfs $ROOTFS

# Make sure init scripts are executable
RUN find $ROOTFS/etc/rc.d/ -exec chmod +x {} \; && \
    find $ROOTFS/usr/local/etc/init.d/ -exec chmod +x {} \;

#get the latest docker
RUN curl -L -o $ROOTFS/usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x $ROOTFS/usr/local/bin/docker

CMD ["/bin/sh", "/make_iso.sh"]
