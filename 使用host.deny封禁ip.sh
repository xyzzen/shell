#!/bin/bash
#通过secure日志封禁登录失败超过3次的ip

ip=$(cat /var/log/secure | grep -i 'Failed password' | awk '{a[$(NF-3)]++} END{for(i in a){print a[i],i | "sort -r -nk 1"}}')

IFS=$'\n'
for deny in $ip; do
   if [ $(echo "$deny" | awk '{print $1}') -gt 3 ]; then
      grep $(echo "$deny" | awk '{print $2}') /etc/hosts.deny >/dev/null 2>&1
      if [ $? -ne 0 ]; then
         echo ALL:$(echo "$c" | awk '{print $2}') >>/etc/hosts.deny
      fi
   fi
done
