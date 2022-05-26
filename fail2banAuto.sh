#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#	Description: Manager Fail2ban
#=================================================

filepath=$(cd "$(dirname "$0")"; pwd) # 获取当前文件$0所在的目录，进入该目录，输出路径
jail_local_file="/etc/fail2ban/jail.local"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"


[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限。" && exit 1

menu_status(){
	if [[ -e ${jail_local_file} ]]; then
		PID=`ps -ef |grep -v grep | grep fail2ban |awk '{print $2}'` # 列出所有程序->查找不包含grep的行->查找包含fail2ban的行->每行按空格或TAB分割，输出文本中的第2项
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
}

Install_Fail2ban(){
    yum install -y epel-release  
    yum install -y fail2ban
}

Update_Fail2ban(){
    yum update -y fail2ban
}

Uninstall_Fail2ban(){
    yum remove -y fail2ban
}

View_Jail(){
    jails=`fail2ban-client status | grep "Jail list" | awk -F "Jail list:\t" '{print $2}' | tr "," " "`
    PS3="选择要查看的监禁: "
    select Jail in ALL $jails QUIT
    do
    if [[ $Jail = "ALL" ]]
    then
        fail2ban-client status
    elif [[ $Jail = "QUIT" ]]
    then
        break
    else
        fail2ban-client status "$Jail"
    fi
    done
}

Start_Jail(){
    jails=`fail2ban-client status | grep "Jail list" | awk -F "Jail list:\t" '{print $2}' | tr "," " "`
    PS3="选择要启动的监禁: "
    select Jail in ALL $jails QUIT
    do
    if [[ $Jail = "ALL" ]]
    then
        fail2ban-client start
    elif [[ $Jail = "QUIT" ]]
    then
        break
    else
        fail2ban-client start "$Jail"
    fi
    done
}

Stop_Jail(){
    jails=`fail2ban-client status | grep "Jail list" | awk -F "Jail list:\t" '{print $2}' | tr "," " "`
    PS3="选择要停止的监禁: "
    select Jail in ALL $jails QUIT
    do
    if [[ $Jail = "ALL" ]]
    then
        fail2ban-client stop
    elif [[ $Jail = "QUIT" ]]
    then
        break
    else
        fail2ban-client stop "$Jail"
    fi
    done
}

Modify_Filter_Config(){
    read -p "输入过滤配置名称，如【nginx】 > " filterName
    if [[ ! -e /etc/fail2ban/filter.d/${filterName}.conf ]]
    then
        read -p "该配置不存在，是否创建？【Y/N】" create
        if [[ $create = "Y" || $create = "y" ]]
        then
            echo -e "###\n# 包含配置\n###\n[INCLUDES]\nbefore = common.conf\n# 还包含其他文件中的配置，在加载本配置文件中配置之前先加载common.conf文件中的配置。\n\n###\n# 定义过滤器\n###\n[Definition]\n_daemon = sshd\n# 定义一个变量，用于描述要过滤的服务名称。\nfailregex = ^%(__prefix_line)s(?:error: PAM: )?[aA]uthentication (?:failure|error) for .* from <HOST>( via \S+)?\s*$\n# 使用正则表达式定义要监禁的主机（登录失败的主机），用<HOST>标识主机IP地址部分。\nignoreregex = \n# 使用正则表达式定义忽略的主机。\n\n### \n# 初始化过滤器\n###\n[Init]\nmaxlines = 10\n# 设置过滤器每次读取日志的行数，每次读取10行做匹配。\n# 过滤器每次从日志中缓冲多少行，进行匹配处理，如果一次读取大量的行，程序会崩溃，系统内存将会不够用。\njournalmatch = _SYSTEMD_UNIT=sshd.service + _COMM=sshd\n# 当在监禁（jail）的配置中定义要使用的后端监视器是systemd时，此项则生效，定义一个服务名，从journa日志\n# 中获取IP地址。">/etc/fail2ban/filter.d/${filterName}.conf
        fi
    fi
    vim /etc/fail2ban/filter.d/${filterName}.conf
}

Modify_Jail_Local_Config(){
    vim /etc/fail2ban/jail.local
}

Start_Fail2ban(){
    systemctl start fail2ban
    systemctl enable fail2ban
}

Reload_Fail2ban(){
    fail2ban-client reload
}

Stop_Fail2ban(){
    systemctl stop fail2ban
}

Restart_Fail2ban(){
    systemctl restart fail2ban
}

UnBan(){
    fail2ban-client set ssh-iptables unbanip 192.168.1.1
    jails=`fail2ban-client status | grep "Jail list" | awk -F "Jail list:\t" '{print $2}' | tr "," " "`
    PS3="选择封禁IP的监禁: "
    select Jail in $jails QUIT
    do
    if [[ $Jail = "QUIT" ]]
    then
        break
    else
        ips=`fail2ban-client status "$Jail" | grep "Banned IP list:" | awk -F "Banned IP list:\t" '{print $2}'`
        PS3="选择要解封的IP: "
        select ip in $ips QUIT
        do
        if [[ $ip = "QUIT" ]]
        then
            break
        else
            fail2ban-client set "$Jail" unbanip "$ip"
        fi
        done
    fi
    done
}

echo -e "  Fail2ban 一键管理脚本 
  ---- Hoothin ----
  ---- fail2ban-regex /var/log/nginx/access.log \"<HOST> -.*- .*HTTP/1.* .* .*$\" ----
  ---- fail2ban-regex /var/log/nginx/access.log /etc/fail2ban/filter.d/nginx-cc.conf ----

  ${Green_font_prefix}1.${Font_color_suffix} 安装 Fail2ban
  ${Green_font_prefix}2.${Font_color_suffix} 更新 Fail2ban
  ${Green_font_prefix}3.${Font_color_suffix} 卸载 Fail2ban
————————————
  ${Green_font_prefix}4.${Font_color_suffix} 查看 jail 信息
  ${Green_font_prefix}5.${Font_color_suffix} 启动 jail
  ${Green_font_prefix}6.${Font_color_suffix} 停止 jail
  ${Green_font_prefix}7.${Font_color_suffix} 编辑 filter 配置
  ${Green_font_prefix}8.${Font_color_suffix} 编辑 jail.local
————————————
 ${Green_font_prefix} 9.${Font_color_suffix} 启动服务端
 ${Green_font_prefix}10.${Font_color_suffix} 重载配置
 ${Green_font_prefix}11.${Font_color_suffix} 停止服务端和所有监禁
 ${Green_font_prefix}12.${Font_color_suffix} 重启 Fail2ban
 ${Green_font_prefix}13.${Font_color_suffix} 解封 IP
 "
menu_status
echo && read -e -p "请输入数字 [1-13]：" num
case "$num" in
	1)
	Install_Fail2ban
	;;
	2)
	Update_Fail2ban
	;;
	3)
	Uninstall_Fail2ban
	;;
	4)
	View_Jail
	;;
	5)
	Start_Jail
	;;
	6)
	Stop_Jail
	;;
	7)
	Modify_Filter_Config
	;;
	8)
	Modify_Jail_Local_Config
	;;
	9)
	Start_Fail2ban
	;;
	10)
	Reload_Fail2ban
	;;
	11)
	Stop_Fail2ban
	;;
	12)
	Restart_Fail2ban
	;;
	13)
	UnBan
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [1-13]"
	;;
esac