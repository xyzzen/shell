#!/bin/bash

#因为ssl vpn必须使用图形化界面才能启动,所以在命令行界面是不能启动的,以下脚本判断是否是xrdg或者显示器连接的图形化界面,不是图形化界面将不执行该脚本,以防误操作,导致故障发生
#在图形化界面的终端执行
#while true;do if [ `/usr/bin/vpn  status |wc -l` -lt 3 ];then /usr/bin/vpn start;sleep 1800;fi;done
#达到监控的目的

xrdgvalue=$(w | awk '{print $3}' | grep ':.*.0' | uniq)
xrdg=$(w | awk '{print $2,$3}' | grep ''${xrdgvalue}'' | grep 'pts' | awk -F '[ /]' '{print $2}' | grep -v 'grep')
xrdg1=$(w | awk '{print $2,$3}' | grep ''${xrdgvalue}'' | grep 'pts' | awk -F '[ /]' '{print $2}' | grep -v 'grep' | wc -l)
nonce=$(tty | awk -F '/' '{print $4}')
gnome=$(w | awk '{print $2,$3}' | grep ':0' | grep 'pts' | awk -F '[ /]' '{print $2}' | grep -v 'grep')
gnome1=$(w | awk '{print $2,$3}' | grep ':0' | grep 'pts' | awk -F '[ /]' '{print $2}' | grep -v 'grep' | wc -l)
option=$1
[ -z $option ] && option='menu'
#xrdg 远程登录检测
if [ "${xrdg1}" -ge 1 ]; then
    for i in $xrdg; do
        if [ "${i}" -eq "${nonce}" ]; then
            case ${option} in
            start)
                /root/iNodeClient/AuthenMngService &
                /root/iNodeClient/iNodeMon &
                /root/iNodeClient/.iNode/iNodeClient &
                ;;
            stop)
                pid=$(ps -ef | grep iNodeClient/ | grep -v 'grep' | awk '{print $2}') && for i in $pid; do kill ${i}; done
                ;;
            restart)
                pid=$(ps -ef | grep iNodeClient/ | grep -v 'grep' | awk '{print $2}') && for i in $pid; do kill ${i}; done
                /root/iNodeClient/AuthenMngService &
                /root/iNodeClient/iNodeMon &
                /root/iNodeClient/.iNode/iNodeClient &
                ;;
            status)
                ps -ef | grep iNodeClient/ | grep -v 'grep'
                ;;
            *)
                echo 'Usage: /usr/bin/vpn {start|stop|status|restart}'
                ;;
            esac
        fi
    done
fi
#直接使用显示器连接检测
if [ "${gnome1}" -ge 1 ]; then
    for s in $gnome; do
        if [ "${s}" -eq "${nonce}" ]; then
            case ${option} in
            start)
                /root/iNodeClient/AuthenMngService &
                /root/iNodeClient/iNodeMon &
                /root/iNodeClient/.iNode/iNodeClient &
                ;;
            stop)
                pid=$(ps -ef | grep iNodeClient/ | grep -v 'grep' | awk '{print $2}') && for i in $pid; do kill ${i}; done
                ;;
            restart)
                pid=$(ps -ef | grep iNodeClient/ | grep -v 'grep' | awk '{print $2}') && for i in $pid; do kill ${i}; done
                /root/iNodeClient/AuthenMngService &
                /root/iNodeClient/iNodeMon &
                /root/iNodeClient/.iNode/iNodeClient &
                ;;
            status)
                ps -ef | grep iNodeClient/ | grep -v 'grep'
                ;;
            *)
                echo 'Usage: /usr/bin/vpn {start|stop|status|restart}'
                ;;
            esac
        fi
    done
fi
#判断不是图形化界面就提醒
tty=$(tty | awk -F'/' '{print $3"/"$4}')
ter=$(w | grep "$tty" | awk '{print $3}' | sed 's#\.##g' | sed 's#\:##g')
vaule=$(w | awk '{print $3}' | grep ':.*.0' | uniq | sed -r 's#:##g' | sed -r 's#\.##g')
for g in $ter; do
    if [ $g -gt ${vaule} ]; then
        case ${option} in
        status)
            ps -ef | grep iNodeClient/ | grep -v 'grep' && exit
            ;;
        stop)
            echo -e "
  "
            echo '当前界面不是图形化界面,不能操作ssl vpn ,请使用图形化界面操作'
            echo -e "
   "
            ;;
        restart)
            echo -e "
  "
            echo '当前界面不是图形化界面,不能操作ssl vpn ,请使用图形化界面操作'
            echo -e "
   "
            ;;
        *)
            echo 'Usage: /usr/bin/vpn {start|stop|status|restart}'
            ;;
        esac
    fi
done
