#/bin/bash
#通用的centos7初始化脚本

####该脚本在windows vscode编辑
#传到Linux上如果出现编码错误需要使用dos2unix转换

#切换镜像源为阿里
edhostname() {
    read -p '请输入修改的主机名: ' name
    hostnamectl set-hostname ${name} && echo '修改成功,当前主机名为: '$(hostname)''
}
alirepo() {
    yum install -y wget >/dev/null 2>&1
    echo '    正在更新软件仓库    '
    mkdir /opt/repo >/dev/null 2>&1 && mv /etc/yum.repos.d/* /opt/repo >/dev/null 2>&1
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
    yum clean all >/dev/null 2>&1 && yum makecache fast >/dev/null 2>&1
    echo '    系统软件源已更新为腾讯镜像源    '
}
#安装必要软件
basesoft() {
    local software=(bash-completion mailx bash-completion-extras lsof vim dos2unix ntpdate gcc-gfortran lrzsz lm_sensors sshpass lshw make iptables-services net-tools tree nmap telnet)
    yum install -y ${software[*]} >>/dev/null 2>&1 && echo '    系统基础必要软件已全部安装成功    ' && echo ' ' | sensors-detect >>/dev/null 2>&1
}

#设置时间和时区
datezone() {
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    /usr/sbin/ntpdate ntp2.aliyun.com >>/dev/null 2>&1 && /usr/bin/timedatectl set-ntp 1 >>/dev/null 2>&1 >>/dev/null 2>&1
    echo "    时区和系统时间已更改为上海 $(date +%F_%T)    "
}
#关闭selinux #关闭firewalld #关闭NetworkManager只使用network管理网卡
disselinux() {
    setenforce 0 >>/dev/null 2>&1
    /usr/bin/sed -ri 's#^(SELINUX=)(.*)#\1disabled#g' /etc/sysconfig/selinux
    echo '    selinux已关闭    '
}
disfire() {
    systemctl stop firewalld >>/dev/null 2>&1
    systemctl disable firewalld >>/dev/null 2>&1
    echo '    firewall已关闭并关闭开机自启    '
}
disnetM() {
    systemctl stop NetworkManager >>/dev/null 2>&1
    systemctl disable NetworkManager >>/dev/null 2>&1
    echo '    NetworkManager已关闭并关闭开机自启    '
}

#内核优化 Kernel optimization
keropt() {
    local ker=$(grep -c 'net.ipv4.tcp_syncookies' /etc/sysctl.conf)
    if [[ $ker -eq 0 ]]; then
        echo '    开始内核优化    '
        cat >>/etc/sysctl.conf <<\EOF
#tcp类
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_retries2 = 5
net.netfilter.nf_conntrack_tcp_timeout_established = 300
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 12
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
#内核类
#崩溃文件记录
kernel.core_pattern=/opt/core.%e.%p.%t
#增加文件描述符限制,表示单个进程较大可以打开的句柄数
fs.file-max = 1000000
#其他
#内核转发功能
net.ipv4.ip_forward = 1
net.core.somaxconn = 1024
#修改防火墙表大小，默认65536
net.netfilter.nf_conntrack_max=655350
net.netfilter.nf_conntrack_tcp_timeout_established=1200
EOF
    fi
    echo '    内核优化参数已添加完毕    '
}

#TCP参数说明：
#net.ipv4.icmp_echo_ignore_all=1  禁ping参数
#net.ipv4.tcp_syncookies = 1表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；
#net.ipv4.tcp_tw_reuse = 1 表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
#net.ipv4.tcp_fin_timeout = 30 表示如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间。默认是60s。
#net.ipv4.tcp_keepalive_time = 1200 表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为20分钟。
#net.ipv4.ip_local_port_range = 1024 65000 表示用于向外连接的端口范围。缺省情况下很小：32768到61000，改为1024到65000。
#net.ipv4.tcp_max_syn_backlog = 8192 表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数。
#net.ipv4.tcp_max_tw_buckets = 5000表示系统同时保持TIME_WAIT套接字的最大数量，如果超过这个数字，TIME_WAIT套接字将立刻被清除并打印警告信息。默认为180000，改为5000。
#net.ipv4.tcp_retries2 = 5 TCP失败重传次数,默认值15，意味着重传15次才彻底放弃，可减少到5，以尽早释放内核资源
#net.core.somaxconn = 4096 选项默认值是128，这个参数用于调节系统同时发起的tcp连接数，在高并发请求中，默认的值可能会导致连接超时或重传，因此，需要结合并发请求数来调节此值。该参数对应系统路径为：/proc/sys/net/core/somaxconn 128
#net.netfilter.nf_conntrack_tcp_timeout_established = 300  设置tcp确认超时时间 300秒，默认 432000 秒（5天）
#net.netfilter.nf_conntrack_tcp_timeout_time_wait = 12  设置tcp等待时间 12秒，超过12秒自动放弃，默认120秒
#net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60  设置tcp关闭等待时间60秒，超过60秒自动关闭，默认60秒

#需要记录在全局环境变量的参数
profile() {
    local conu=$(grep -c 'ulimit -c unlimited' /etc/profile)
    if [[ conu -eq 0 ]]; then
        echo '    开始添加全局环境参数    '
        cat >>/etc/profile <<\EOF
#崩溃文件最大化,程序濒繁崩溃会导致根容量被占满
ulimit -c unlimited
#30分钟不操作就断开终端
TMOUT=1800
#关闭邮件提示
unset MAILCHECK
EOF
        echo '    全局环境变量参数添加完毕    '
    fi
}

#vim简单优化
edvim() {
    local vimstatus=$(grep -c 'set tabstop=4' /root/.vimrc) >>/dev/null 2>&1
    if [[ $vimstatus -eq 0 ]]; then
        echo '    开始优化vim    '
        cat >>/root/.vimrc <<\EOF
set nocompatible                    " vim按照自己的方式工作,不兼容vi
syntax on                           " 语法高亮
set t_Co=256                        " 告知配色，终端支持256色
"colorscheme atom-dark               " vim 主题
set linespace=16                    " 设置行高
"set number                          " 显示行号
set cursorline                      " 光标所在行高亮
filetype indent on                  " 文件类型识别
set noerrorbells                    " 关闭错误提示音
set vb t_vb=                        " 关闭错误提示音
set showmatch                       " 自动显示匹配的括号
set wildmenu                        " 在命令行模式 可以通过TAB键自动补全路径,并提供菜单选择
set scrolljump=5                    " 自动向下或向上滚动5行,配合 scrolloff 使用
set scrolloff=3                     " 屏幕上下还有3行,配合 scrolljump 使用
set laststatus=2                    " 显示状态栏
set ruler                           " 显示状态栏
set tabstop=4                       " 一个tab为4个空格
set shiftwidth=4                    " 当执行<<和>>时为4个空格,而非8个空格
" 开启expandtab时，Vim会使用和tab宽度相等的空格来模拟tab字符,始终保持tab在所有环境中的宽度一致.
set expandtab
set autoindent                      " 每一行自动和上一行保持相同的缩进
set hlsearch                        " 高亮显示搜索的结果
set incsearch                       " 实时匹配搜索
" 把编辑区域的前景色从默认的纯白改成#eeeeee，把背景色改成泊学一直使用的藏蓝#252B3A
hi Normal        guifg=#eeeeee guibg=#252b3a
" 高亮
hi Visual        guifg=#cdfbff guibg=#1bb1b2
" 修改当前行高亮的颜色
hi CursorLine    guibg=#2F374D
" 把光标的颜色设置成蓝色
hi Cursor        guifg=NONE  guibg=#2196f3
" 修改行号列的背景色, bg就是指Normal中设置的guibg颜色
hi LineNr        guibg=bg
" 修改状态栏的样式
hi StatusLine    guifg=#526669 guibg=bg
hi StatusLineNC  guifg=#526669 guibg=#252b3a gui=none
EOF
        echo '    vim已优化完毕    '
    fi
}

#配置邮件,下面是阿里云企业邮箱配置
edmail() {
    echo '开始配置'
    local mailstatus=$(grep -c 'smtp-auth-user' /etc/mail.rc)
    if [[ ${mailstatus} -eq 0 ]]; then
        cat >>/etc/mail.rc <<\EOF
    set from=server@xxx.com smtp=smtp.mxhichina.com
    set smtp-auth-user=server@xxx.com smtp-auth-password=123456aa
    set smtp-auth=login
EOF
        echo ' 配置完成 '
    fi

}

#安全优化,关闭没必要的用户以及组
sec() {
    if [ -f /root/.ssh/keylogin ]; then
        echo ''
    else
        local rxmail='xxx@xxx.com'
        local sshfile='/etc/ssh/sshd_config'
        /usr/bin/expect <<-EFO
    spawn ssh-keygen -t rsa  >>/dev/null 2>&1
expect {
        "Enter file in which to save the key (/root/.ssh/id_rsa):" { send "/root/.ssh/keylogin\r";exp_continue};
        "Overwrite (y/n)?" { send "y\r";exp_continue};
        "Enter passphrase (empty for no passphrase):" { send "\r";exp_continue};
        "Enter same passphrase again:" { send "\r";exp_continue};
}
EFO
        cat /root/.ssh/keylogin | mail -s "$(hostname -I | awk '{print $1}')" ${rxmail}
        #ssh安全优化
        cat >>${sshfile} <<\EOF
Port 52333
UseDNS no
#禁止密码登录,必须使用秘钥
PubkeyAuthentication yes
EOF
        #sed -ri 's#PasswordAuthentication yes#PasswordAuthentication no#g' ${sshfile}
        sed -ri 's#(AuthorizedKeysFile    )(.*)#\1.ssh/keylogin.pub#g' ${sshfile}
    fi
}

menu() {
    cat <<EOF
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
注意:
1. 该脚本只可用于centos7-7.6系列 centos8禁用!!!
2. yum仓库为阿里源 原有仓库文件会备份到/opt/repo
3. 查看菜单输入menu
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++---+++      0. 修改主机名		     ++        ++
+++---+++      1. 切换镜像源为腾讯源		++         ++
+++---+++      2. 安装系统基础必要软件	++        ++
+++---+++      3. 关闭selinux	        ++      ++
+++---+++      4. 同步时间和时区		     ++     ++
+++---+++      5. 关闭firewalld			 ++    ++
+++---+++      6. 关闭NetworkManager只使用network管理网卡 ++  ++
+++---+++      7. 内核优化		      ++     ++
+++---+++      8. 记录在全局变量的参数	++      ++
+++---+++      9. vim简单优化	++      ++
+++---+++      10. 配置发件邮件	++      ++
+++---+++      11. 安全优化包括ssh	++      ++
+++---+++      12. 批量执行1-11的操作	++      ++
+++---+++      2233. 退出菜单	++      ++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
data:   2020-11-20
author: snuglove
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
EOF
}
menu
trap "echo  禁止挂起取消 退出请输入 2233 " HUP INT TSTP KILL
while true; do
    read -p '请输入序号[0-11]: ' num
    case $num in
    menu)
        menu
        ;;
    0)
        edhostname #修改主机名
        continue
        ;;
    1)
        alirepo #切换镜像源为腾讯源
        ;;
    2)
        basesoft #安装必要软件
        ;;
    3)
        disselinux #关闭selinux
        ;;
    4)
        datezone #设置时间和时区
        ;;
    5)
        disfire #关闭firewalld
        ;;
    6)
        disnetM #关闭NetworkManager只使用network管理网卡
        ;;
    7)
        keropt #内核优化
        ;;
    8)
        profile #记录在全局环境文件中的参数.
        ;;
    9)
        edvim #vim简单优化
        ;;
    10)
        edmail #配置发件邮件
        ;;
    11)
        sec #安全优化
        ;;
    2233)
        exit
        ;;
    12)
        alirepo
        basesoft
        disselinux
        datezone
        disfire
        disnetM
        keropt
        profile
        vim
        mail
        sec
        ;;
    *)
        echo '警告!! 输入错误,请输入正确序列号[[查看菜单输入 menu 退出输入 2233 ]]'
        ;;
    esac
done
