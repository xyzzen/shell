#!/bin/bash

#需要备份库或表
bf_db1="blog"
bf_db2="jpress"
bf_db3=""
bf_db4=""
bf_table1=""
bf_table2=""
bf_table3=""
bf_table4=""

#备份目录及名称
bf_dir="/backup"
date1=`date +%y%m%d-%H%M`
#打包压缩目录
tar="/backup/tar/"

#定义数据库信息
mysql_user="root"
mysql_pass="123456.."
mysql_host="172.16.1.51"
mysql_bf='-R --triggers'
mysql_conn="-u$mysql_user -p$mysql_pass  $mysql_bf"
name1="${bf_db1}_${date1}"
name2="${bf_db2}_${date1}"


#备份成.sql
cd ${bf_dir}
mysqldump $mysql_conn $bf_db1 $mysql_bf  > ${name1}.sql
mysqldump $mysql_conn $bf_db2 $mysql_bf  > ${name2}.sql

#打包压缩
cd $tar
tar zchf  ${name1}.tar.gz  ..${name1}.sql &>/dev/null
tar zchf  ${name2}.tar.gz  ..${name2}.sql &>/dev/null

#删除15天前的.sql文件
find $bf_dir -name '*.sql'  -mtime +15 |xargs rm

#删除7天前的压缩文件
find $tar -name '*.tar.gz'  -mtime +7 |xargs rm
