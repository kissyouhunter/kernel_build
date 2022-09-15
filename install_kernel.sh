#!/bin/bash

TIME() {
[[ -z "$1" ]] && {
	echo -ne " "
} || {
     case $1 in
	r) export Color="\e[31;1m";;
	g) export Color="\e[32;1m";;
	b) export Color="\e[34;1m";;
	y) export Color="\e[33;1m";;
	z) export Color="\e[35;1m";;
	l) export Color="\e[36;1m";;
	w) export Color="\e[29;1m";;
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}

# 删除 linux-image-current-meson64
apt remove -y linux-image-current-meson64
#读取新、旧内核版本
#read -p "please enter the new kernel:" N1
#read -p "please enter the old kernel:" N2
#read -p "please enter the kernel_code:" N3
#number1=$N1
#number2=$N2
#number3=$N3
#即将安装的内核版本
new_kernel=n1kernel-kissyouhunter
#安装完新内核删除老内核版本
old_kernel=5.4.205-kissyouhunter
#内核源码
kernel_code=linux-kernelnumber
#各文件路径变量
root_path=/root
boot_path=/boot
dtb_path=/boot/dtb/amlogic
new_dtb_path=/arch/arm64/boot/dts/amlogic
modules_path=/usr/lib/modules
new_header_path=/root/header
cd ${root_path}
#解压 Armbian 源码包
#unzip ${kernel_code}.tar.gz.zip
#rm -f ${kernel_code}.tar.gz.zip
tar zxf ${kernel_code}.tar.gz
rm -f ${kernel_code}.tar.gz
mv ${kernel_code} ${new_kernel}

if [ -a "${root_path}/${new_kernel}" ]; then
	TIME g " --------------------文件解压----------------------"
	TIME g "   _____ _    _  _____ _____ ______  _____ _____ _ "
	TIME g "  / ____| |  | |/ ____/ ____|  ____|/ ____/ ____| |"
	TIME g " | (___ | |  | | |   | |    | |__  | (___| (___ | |"
	TIME g "  \___ \| |  | | |   | |    |  __|  \___ \\___ \| |"
	TIME g "  ____) | |__| | |___| |____| |____ ____) |___) |_|"
	TIME g " |_____/ \____/ \_____\_____|______|_____/_____/(_)"
else
	TIME r " ---------------文件解压----------------"
	TIME r "______ ___  _____ _      ___________ _ "
	TIME r "|  ___/ _ \|_   _| |    |  ___|  _  \ |"
	TIME r "| |_ / /_\ \ | | | |    | |__ | | | | |"
	TIME r "|  _||  _  | | | | |    |  __|| | | | |"
	TIME r "| |  | | | |_| |_| |____| |___| |/ /|_|"
	TIME r "\_|  \_| |_/\___/\_____/\____/|___/ (_)"
    exit 0
fi

#安装内核模块
cd ${new_kernel}
mkdir -p ${new_header_path}
make modules_install && make install
make INSTALL_HDR_PATH=${new_header_path} headers_install
cd ${boot_path} && cp -r vmlinuz-${new_kernel} zImage && cp -r uInitrd uInitrd-${new_kernel}
cd ${dtb_path} && rm -f *
cp ${root_path}/${new_kernel}/${new_dtb_path}/*.dtb ${dtb_path}
#打包header
cd ${new_header_path} && tar zcf header-${new_kernel}.tar.gz * && cp -r header-${new_kernel}.tar.gz ${root_path}
#cp ${root_path}/${new_kernel}/${new_dtb_path}/meson-gxl-s905d-phicomm-n1-thresh.dtb ${dtb_path}
#打包boot模块
cd ${boot_path} && tar zcf boot-${new_kernel}.tar.gz *-${new_kernel} && cp -r boot-${new_kernel}.tar.gz ${root_path}
#打包dtb文件
cd ${dtb_path} && tar zcf dtb-amlogic-${new_kernel}.tar.gz *.dtb && cp -r dtb-amlogic-${new_kernel}.tar.gz ${root_path}
#打包modules模块
cd ${modules_path} && tar zcf modules-${new_kernel}.tar.gz ${new_kernel} && cp -r modules-${new_kernel}.tar.gz ${root_path}
#删除多余内核文件
rm -r ${boot_path}/*-${old_kernel} && rm -r ${modules_path}/${old_kernel}
#删除打文件
rm -r ${boot_path}/boot-${new_kernel}.tar.gz
rm -r ${dtb_path}/dtb-amlogic-${new_kernel}.tar.gz
rm -r ${modules_path}/modules-${new_kernel}.tar.gz
rm -rf ${root_path}/${new_kernel}
#判断文件是否存在
if [[ -a "${root_path}/boot-${new_kernel}.tar.gz" && -a "${root_path}/dtb-amlogic-${new_kernel}.tar.gz" && -a "${root_path}/modules-${new_kernel}.tar.gz" && -a "${root_path}/header-${new_kernel}.tar.gz" ]]; then
	TIME g " ----------------------内核------------------------"
	TIME g "   _____ _    _  _____ _____ ______  _____ _____ _ "
	TIME g "  / ____| |  | |/ ____/ ____|  ____|/ ____/ ____| |"
	TIME g " | (___ | |  | | |   | |    | |__  | (___| (___ | |"
	TIME g "  \___ \| |  | | |   | |    |  __|  \___ \\___ \| |"
	TIME g "  ____) | |__| | |___| |____| |____ ____) |___) |_|"
	TIME g " |_____/ \____/ \_____\_____|______|_____/_____/(_)"
else
	TIME r " ----------------内核-------------------"
	TIME r "______ ___  _____ _      ___________ _ "
	TIME r "|  ___/ _ \|_   _| |    |  ___|  _  \ |"
	TIME r "| |_ / /_\ \ | | | |    | |__ | | | | |"
	TIME r "|  _||  _  | | | | |    |  __|| | | | |"
	TIME r "| |  | | | |_| |_| |____| |___| |/ /|_|"
	TIME r "\_|  \_| |_/\___/\_____/\____/|___/ (_)"
fi
