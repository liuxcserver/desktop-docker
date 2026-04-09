#!/bin/bash

# --- 1. 密码配置 ---
PASSWORD=${VNC_PASSWORD:-"123456"}

# 创建用户目录
mkdir -p /home/user/.vnc
chown -R user:user /home/user

# 设置 VNC 密码 (用于浏览器访问)
echo "$PASSWORD" | vncpasswd -f > /home/user/.vnc/passwd
chmod 600 /home/user/.vnc/passwd

# 设置 XRDP 用户密码 (用于 Windows 远程桌面)
# 如果用户不存在则创建
if id "user" &>/dev/null; then
    echo "user:$PASSWORD" | chpasswd
else
    useradd -m -s /bin/bash user
    echo "user:$PASSWORD" | chpasswd
    usermod -aG sudo user
fi

# --- 2. 创建 VNC xstartup 脚本 ---
cat > /home/user/.vnc/xstartup <<EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec /usr/bin/startxfce4
EOF
chmod +x /home/user/.vnc/xstartup
chown user:user /home/user/.vnc/xstartup

# --- 3. GPU 配置 ---
export LIBVA_DRIVER_NAME=iHD
chmod 666 /dev/dri/* 2>/dev/null || true

# --- 4. 启动 VNC Server ---
echo "Starting TigerVNC Server..."
# -SecurityTypes None 表示在 VNC 协议层不加密（由 noVNC 层处理或内网通信）
su - user -c "vncserver :1 -geometry 1920x1080 -depth 24 -SecurityTypes None"

# --- 5. 启动 noVNC ---
echo "Starting noVNC..."
# 将 6901 端口的 Web 请求转发到 localhost:5901
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6901 &

# --- 6. 启动 Supervisor (管理 XRDP 和 DBus) ---
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf