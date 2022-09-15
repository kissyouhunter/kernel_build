# author kissyouhunter
# date 03/13/2022

import os
os.system('apt update && apt upgrade -y && apt remove -y linux-image-current-meson64')
# input the kernel version
#number1 = input('please enter the new kernel: ')
#number2 = input('please enter the old kernel: ')
#number3 = input('please enter the kernel code: ')
#print(number1,number2,number3)

author = 'kissyouhunter'
new_kernel = n1kernel+'-'+author
#print(new_kernel)
old_kernel = '5.10.100-'+author
#print(old_kernel)
kernel_code = 'linux-'+kernelnumber
#print(kernel_code)

# directories
root_path = '/root'
boot_path = '/boot'
dtb_path = '/boot/dtb/amlogic'
new_dtb_path = '/arch/arm64/boot/dts/amlogic'
modules_path = '/usr/lib/modules'

# execute
#os.system('unzip '+root_path+'/'+kernel_code+'.tar.gz.zip')
#os.system('rm -f '+root_path+'/'+kernel_code+'.tar.gz.zip')
os.system('tar zxvf '+root_path+'/'+kernel_code+'.tar.gz')
os.system('rm -f '+root_path+'/'+kernel_code+'.tar.gz')
os.system('mv '+root_path+'/'+kernel_code+' '+root_path+'/'+new_kernel)

#file_exists = os.path.exists(root_path+'/'+new_kernel)
#print(file_exists)

import os.path
isdir = os.path.isdir(root_path+'/'+new_kernel)
if isdir == True:
    print('success!')
else:
    print('failed!')
    exit

# install kernel
os.system('cd '+root_path+'/'+new_kernel+' && make modules_install && make install')
os.system('cp -r '+boot_path+'/vmlinuz-'+new_kernel+' '+boot_path+'/zImage')
os.system('cp -r '+boot_path+'/uInitrd'+' '+boot_path+'/uInitrd-'+new_kernel)
os.system('rm -r '+dtb_path+'/*')
os.system('cp '+root_path+'/'+new_kernel+'/'+new_dtb_path+'/*.dtb '+dtb_path)

# copy booy to root
os.system('cd '+boot_path+' && tar zcvf boot-'+new_kernel+'.tar.gz '+'*-'+new_kernel)
os.system('mv '+boot_path+'/boot-'+new_kernel+'.tar.gz '+root_path)
os.system('rm -f *-'+boot_path+'/*-'+old_kernel)
# copy dtb to root
os.system('cd '+dtb_path+'&& tar zcvf dtb-amlogic-'+new_kernel+'.tar.gz *.dtb')
os.system('mv '+dtb_path+'/dtb-amlogic-'+new_kernel+'.tar.gz '+root_path)
# copy modules to root
os.system('cd '+modules_path+' && tar zcvf modules-'+new_kernel+'.tar.gz '+new_kernel)
os.system('mv '+modules_path+'/modules-'+new_kernel+'.tar.gz '+root_path)
os.system('rm -rf '+modules_path+'/'+old_kernel)
# delete folder
os.system('rm -rf '+root_path+'/'+new_kernel)

file1_exists = os.path.exists(root_path+'/boot-'+new_kernel+'.tar.gz')
file2_exists = os.path.exists(root_path+'/dtb-amlogic-'+new_kernel+'.tar.gz')
file3_exists = os.path.exists(root_path+'/modules-'+new_kernel+'.tar.gz')
if file1_exists == True and file2_exists == True and file3_exists == True:
    print('   _____ _    _  _____ _____ ______  _____ _____ _ ')
    print('  / ____| |  | |/ ____/ ____|  ____|/ ____/ ____| |')
    print(' | (___ | |  | | |   | |    | |__  | (___| (___ | |')
    print('  \___ \| |  | | |   | |    |  __|  \___ \\___ \| |')
    print('  ____) | |__| | |___| |____| |____ ____) |___) |_|')
    print(' |_____/ \____/ \_____\_____|______|_____/_____/(_)')
else:
    print('______ ___  _____ _      ___________ _ ')
    print('|  ___/ _ \|_   _| |    |  ___|  _  \ |')
    print('| |_ / /_\ \ | | | |    | |__ | | | | |')
    print('|  _||  _  | | | | |    |  __|| | | | |')
    print('| |  | | | |_| |_| |____| |___| |/ /|_|')
    print('\_|  \_| |_/\___/\_____/\____/|___/ (_)')

exit
