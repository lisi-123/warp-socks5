#!/bin/bash

# 更新软件包列表
apt-get update

# 安装必需的软件包
apt install sudo -y
sudo apt install git -y
sudo apt install curl -y
sudo apt install nano -y

# 网络调优
CONF="/etc/sysctl.conf"

# 删除旧配置
sed -i '
/net.core.default_qdisc/d
/net.ipv4.tcp_congestion_control/d
/net.ipv4.tcp_ecn/d
/net.ipv4.tcp_fastopen/d
/net.ipv4.tcp_mtu_probing/d
/net.ipv4.tcp_notsent_lowat/d
/net.ipv4.tcp_limit_output_bytes/d
/net.ipv4.tcp_sack/d
/net.ipv4.tcp_timestamps/d
/net.ipv4.tcp_window_scaling/d
' "$CONF"

# 写入新配置
cat >> "$CONF" << 'EOF'

# BBR 优化
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP 队列
net.core.somaxconn = 4096

# TCP 优化
net.ipv4.tcp_ecn=0
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=0

EOF

# 应用配置
sysctl --system

# 修改为上海时区
sudo timedatectl set-timezone Asia/Shanghai

# 安装warp并设置本地socks5代理
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh <<< $'2\n12\n1\n1\n40000\n'

# 添加定时任务（凌晨4:30重启v2node，每5分钟检测warp状态，自动清理vps日志）
CRON_JOB1='30 4 * * * /usr/bin/v2node restart'
CRON_JOB2='*/5 * * * * /root/v2bx-scr/socks5-check.sh'
CRON_JOB3='0 5 * * * /root/v2bx-scr/clean_logs.sh'

# 将任务添加到 crontab 并避免重复
(crontab -l 2>/dev/null; echo "$CRON_JOB1"; echo "$CRON_JOB2"; echo "$CRON_JOB3") | sort -u | crontab -

# 输出完成信息
echo "已自动配置warp解锁"
