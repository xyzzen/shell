#!/bin/bash
#脚本用于显示cpu,内存,硬盘等信息用来确认硬件信息


#cpu
echo 'cpu核数为:' $(lscpu  |grep 'Core(s) per socket:'|awk '{print $NF}')
echo 'cpu线程数为:' $(lscpu  |grep 'CPU(s):'|awk '{print $NF}') 
echo 'cpu' $(lscpu  |grep 'Intel(R)')
#硬盘
yum install -y smartmontools >>/dev/null 2>&1
smartctl -a /dev/sda|head -19
smartctl -a /dev/sdb|head -19

#内存
#目前采购的内存要求都是DDR4的
#所以内存的查询规则是按照DDR4类型检测的,不是这个类型就查不出来
echo '内存的型号是' $(dmidecode |grep -a3 'DDR4'|tail -1|awk '{print $NF}')
echo '内存的大小是' $(dmidecode |grep -a5 'DDR4' |head -1|awk '{print $(NF-1),$NF}')

#主板型号
echo '主板商:' $(dmidecode |grep -A5 "System Information$" |awk 'NR==2{print $NF}')
echo '主板型号:' $(dmidecode |grep -A5 "System Information$" |awk 'NR==3{print $NF}')

#显卡型号
nvidia-smi -L|sed -r 's#(GPU.*:)(.*)(\(UUID.*)#显卡型号为:\2#g'
nvidia-smi |awk  'NR==3' |sed -r 's#(\|)(.*)(\|)#显卡驱动版本以及支持的cuda版本为:\2#g'
nvidia-smi -q|grep -A1 'FB Memory Usage'|grep 'Total'|sed -r 's#(.*Total.*:)(.*)#显卡显存大小为:\2#g'

#查询网卡的数量
yum install -y pciutils >>/dev/null 2>&1
echo '本机网卡个数为:' $(lspci |grep 'Ethernet controller'|wc -l)
