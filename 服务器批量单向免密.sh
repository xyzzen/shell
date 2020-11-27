#!/bin/bash
#本脚本在vscode下编写 Linux执行报错请使用dos2unix转码

#本地服务器生成免密的秘钥
/usr/bin/expect <<-EFO
    spawn ssh-keygen -t rsa  >>/dev/null 2>&1
expect {
        "Enter file in which to save the key (/root/.ssh/id_rsa):" { send "/root/.ssh/nosekey\r";exp_continue};
        "Overwrite (y/n)?" { send "y\r";exp_continue};
        "Enter passphrase (empty for no passphrase):" { send "\r";exp_continue};
        "Enter same passphrase again:" { send "\r";exp_continue};
}
EFO

#变量 批量管理的服务器信息
host='35.229.255.73'
port=(55222 45222 3542  5222 22233)
serpass='shell@2020'
for i in ${port[*]}; do
    sshpass -p ${serpass} ssh-copy-id -o StrictHostKeyChecking=no -p${i} -i /root/.ssh/nosekey root@${host}
done

#将秘钥管理软件放到用户环境变量中
#这里需要根据自己的shell解释器添加变量
cat >>~/.zshrc <<\EOF
eval `ssh-agent` && ssh-add /root/.ssh/nosekey
EOF