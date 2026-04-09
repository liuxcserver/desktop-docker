#!/bin/bash

# --- 1. 密码配置 ---
# 读取环境变量 VNC_PASSWORD，默认为 123456
PASSWORD=${VNC_PASSWORD:-"123456"}

# 设置 KasmVNC 密码
mkdir -p /home/user/.vnc
echo "$PASSWORD" | vncpasswd -f > /home/user/.vnc/passwd
chmod 600 /home/user/.vnc/passwd
chown -R user:user /home/user/.vnc

# 设置 XRDP 用户密码 (用于 Windows 远程桌面登录)
# 如果用户不存在则创建，存在则更新密码
if id "user" &>/dev/null; then
    echo "user:$PASSWORD" | chpasswd
else
    useradd -m -s /bin/bash user
    echo "user:$PASSWORD" | chpasswd
    usermod -aG sudo user
fi

# --- 2. GPU 硬件加速配置 (针对 Intel N150) ---
# N150 使用 iHD 驱动
export LIBVA_DRIVER_NAME=iHD
# 赋予普通用户访问显卡设备的权限
chmod 666 /dev/dri/* 2>/dev/null || true

# --- 3. 启动 Supervisor ---
echo "Starting Desktop Environment..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf