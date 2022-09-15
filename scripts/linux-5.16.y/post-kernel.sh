#!/bin/bash

# begin 检查环境参数
if [ $# -ne 2 ];then
    echo "$0 env_file kernel-version"
    exit 1
fi

ENV_FILE=$1
source $ENV_FILE
VER=$2
echo "Posting kernel $VER ..."

case $CC in
    clang*) CLANG=1;;
         *) CLANG=0;;
esac

if [ $CLANG -eq 1 ];then
    export MFLAGS="LLVM=1 LLVM_IAS=1"
else
    export MFLAGS=""
fi

if [ -z "$FAKE_ROOT" ];then
    FAKE_ROOT=/opt/armbian-bullseye-root
fi

export LOCALVERSION=""
POST_HOME="/opt/kernel"
# end 检查环境参数

function set_localversion() {
    cd $KERNEL_SRC_HOME
    echo "Set localversion ... "
    scripts/setlocalversion
    echo "done"
    echo
}

function clean_env() {
    echo -n "Clean ${FAKE_ROOT} environments ... "
    MNTS="/lib/modules ${FAKE_ROOT}/lib/modules  ${FAKE_ROOT}/boot"
    for MNT in $MNTS;do
	 i=1
         while :;do
             umount -f ${MNT} 2>/dev/null
	     if [ $? -eq 0 ];then
                 break
             else
	         let i++

	         if [ $i -ge 3 ];then
		     echo "umount ${MNT} failed!"
                     exit 1
	         fi
		 sleep 1
	     fi
	 done
    done

    rm -rf ${FAKE_ROOT}/lib/modules && mkdir ${FAKE_ROOT}/lib/modules
    rm -rf ${FAKE_ROOT}/boot && mkdir ${FAKE_ROOT}/boot
    echo "done"
    echo
}

function clean_exit() {
    clean_env
    echo $1
    exit $2
}

function init_env() {
    echo -n "Init ${FAKE_ROOT} environments ... "
    rm -rf ${FAKE_ROOT}/lib/modules && mkdir ${FAKE_ROOT}/lib/modules
    rm -rf ${FAKE_ROOT}/boot && mkdir ${FAKE_ROOT}/boot 
    mount -t tmpfs none ${FAKE_ROOT}/lib/modules || clean_exit "mount failed" 1
    mount -t tmpfs none ${FAKE_ROOT}/boot || clean_exit "mount failed" 2
    mount -o bind ${FAKE_ROOT}/lib/modules /lib/modules || clean_exit "mount failed" 3
    echo "done"
    echo
}

function make_dtbs() {
    (
        cd $KERNEL_SRC_HOME
        echo "Make dtbs ... "
        make CC=${CC} LD=${LD} $MFLAGS dtbs || clean_exit "make dtbs failed" 1
	echo "Dtbs make done!"
    )
}

function modules_install() {
    # make modules_install
    (
        cd $KERNEL_SRC_HOME
	echo "Install modules ..."
        make CC=${CC} LD=${LD} $MFLAGS modules_install || clean_exit "install modules failed" 1
	echo "Modules installed!"
	echo
    )
}

function headers_install() {
    (
    	cd $KERNEL_SRC_HOME
	echo "Install headers ..."
	if [ -d $HDR_PATH ];then
	    rm -rf $HDR_PATH/*
	else
	    mkdir -p $HDR_PATH
	fi
	make headers_install INSTALL_HDR_PATH=$HDR_PATH
	cd $HDR_PATH
	echo "Header installed!"
	echo
    )
}

function update_initramfs() {
    (
        cd $KERNEL_SRC_HOME
        echo "Copy kernel files to ${FAKE_ROOT}/boot/ ..."
        cp -v System.map ${FAKE_ROOT}/boot/System.map-${VER}
        cp -v .config ${FAKE_ROOT}/boot/config-${VER}
        cp -v arch/arm64/boot/Image ${FAKE_ROOT}/boot/vmlinuz-${VER}
	cp -v /etc/resolv.conf ${FAKE_ROOT}/etc/
	echo "Copy done!"
	echo

	# for cross compile
	if [ `uname -m` == 'x86_64' ];then
	    rm -f ${FAKE_ROOT}/usr/bin/qemu-aarch64*

 	    # debian & ubuntu, can install qemu-user-static
	    # otherwise, install qemu-linux-user
	    if [ -f /usr/bin/qemu-aarch64-static ];then
	        [ -f ${FAKE_ROOT}/usr/bin/qemu-aarch64-static ] || cp -v /usr/bin/qemu-aarch64-static ${FAKE_ROOT}/usr/bin/
            elif [ -f /usr/bin/qemu-aarch64 ];then
	        [ -f ${FAKE_ROOT}/usr/bin/qemu-aarch64 ] || cp -v /usr/bin/qemu-aarch64 ${FAKE_ROOT}/usr/bin/
	        [ -f ${FAKE_ROOT}/usr/bin/qemu-aarch64-binfmt ] || cp -v /usr/bin/qemu-aarch64-binfmt ${FAKE_ROOT}/usr/bin/
	        echo "Start systemd-binfmt.service ... "
  	        [ -f /sbin/qemu-binfmt-conf.sh ] && /sbin/qemu-binfmt-conf.sh --systemd aarch64
	        systemctl start systemd-binfmt.service
	        if [ $? -ne 0 ];then
	            echo "start systemd-binfmt.service failed!"
	            exit 1
	        else
	            systemctl status systemd-binfmt.service
                fi
	    fi
	fi

        if [ -z ${INITRAMFS_COMPRESS} ];then
            INITRAMFS_COMPRESS=gzip
        fi
        echo "Use [${INITRAMFS_COMPRESS}] to compress initrd ... "
        sed -e "/COMPRESS=/d" -i ${FAKE_ROOT}/etc/initramfs-tools/initramfs.conf
        echo "COMPRESS=${INITRAMFS_COMPRESS}" >> ${FAKE_ROOT}/etc/initramfs-tools/initramfs.conf
        chroot ${FAKE_ROOT} update-initramfs -c -k ${VER} || clean_exit "update initramfs failed!" 1
        echo "Update initramfs done!"
	echo

	# for cross compile
	if [ `uname -m` == 'x86_64' ] && [ ! -f /usr/bin/qemu-aarch64-static ];then
	   echo "Stop systemd-binfmt.service ... "
	   systemctl stop systemd-binfmt.service 
	   systemctl status systemd-binfmt.service 
	fi
    )
}

function archive_dtbs() {
    (
        cd $KERNEL_SRC_HOME
	echo "Archive dtbs ..."
	PLATFORMS="allwinner amlogic rockchip"
	for PLAT in $PLATFORMS;do
            echo -n "  -> Archive platform ${PLAT} dtbs to $POST_HOME/dtb-${PLAT}-${VER}.tar.gz ... "
            cd $KERNEL_SRC_HOME/arch/arm64/boot/dts/${PLAT}
            tar czf $POST_HOME/dtb-${PLAT}-${VER}.tar.gz *.dtb || clean_exit "archive dtbs failed!" 1
            echo "done"
        done
        echo "Archive dtbs done!"
    )
}

function archive_boot() {
    (
        echo -n "Archive boot files to $POST_HOME/boot-${VER}.tar.gz ... "
        cd ${FAKE_ROOT}/boot && \
	   tar cf - *${VER} | pigz -9 > $POST_HOME/boot-${VER}.tar.gz || clean_exit "archive boot files failed!" 1
	echo "done!"
    )
}

function archive_modules {
    (
        echo -n "Archive modules to $POST_HOME/modules-${VER}.tar.gz ... "
        cd ${FAKE_ROOT}/lib/modules && \
	    tar cf - ${VER} | pigz -9 > $POST_HOME/modules-${VER}.tar.gz || clean_exit "archive modules failed!" 1
	echo "done!"
    ) 
}

function archive_headers {
    (
        echo -n "Archive headers to $POST_HOME/header-${VER}.tar.gz ... "
        cd ${HDR_PATH} && \
	    tar cf - . | pigz -9 > $POST_HOME/header-${VER}.tar.gz || clean_exit "archive headers failed!" 1
	echo "done!"
    ) 
}

trap "clean_exit" 2 3 15

echo
echo "#########################################################################################"
echo -n `date`
echo " : Post kernel starting ..."
echo "#########################################################################################"
echo
# 环境初始化
init_env
set_localversion
make_dtbs
modules_install
headers_install
update_initramfs
archive_dtbs 
archive_boot
archive_modules
archive_headers
clean_env
sync
echo "#########################################################################################"
echo -n `date`
echo " : Post Kernel Done!"
echo "#########################################################################################"
echo
exit 0
