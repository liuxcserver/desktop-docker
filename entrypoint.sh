#!/bin/bash

# --- 1. 定义默认值 ---
USER_NAME=${USER_NAME:-appuser}
USER_PASS=${USER_PASS:-123456} # 默认密码
USER_HOME="/config"

# 判断目录是否存在
if [ ! -d "$USER_HOME" ]; then
    echo "🚨 错误: 目录 $USER_HOME 不存在！"
    exit 1
fi

# --- 2. 获取元数据 ---
TARGET_UID=$(stat -c %u $USER_HOME)
TARGET_GID=$(stat -c %g $USER_HOME)
TARGET_MODE=$(stat -c %f $USER_HOME) # 获取十六进制文件类型/模式
TARGET_PERMISSIONS=$(stat -c %a $USER_HOME) # 获取权限数字 (如 755)
echo "🔍 探测到当前权限: UID=$TARGET_UID, GID=$TARGET_GID, Mode=$TARGET_PERMISSIONS"

# --- 3. 核心逻辑：判断是否为 "全新空目录" ---
# Docker 自动创建的目录通常是: UID=0, GID=0, Permission=755, 且目录为空
# 判断是否为空目录
IS_EMPTY_DIR=false
if [ -z "$(ls -A $USER_HOME 2>/dev/null)" ]; then
    IS_EMPTY_DIR=true
fi

# 👇 策略 A: 如果是 Root (0:0) 且 目录不为空
# 这是一个极其危险的信号，可能是挂载了宿主机的 /etc, /var 或者根目录
if [ "$TARGET_UID" -eq 0 ] && [ "$TARGET_GID" -eq 0 ] && [ "$IS_EMPTY_DIR" = false ]; then
    echo "🛑 严重错误：检测到挂载了宿主机的系统关键目录 (Root 拥有且非空)！"
    echo "💡 为了防止破坏宿主机系统，容器已停止启动。"
    echo "💡 请检查你的 docker run 命令，不要将宿主机的系统目录挂载到 /config。"
    exit 1
fi

# 👇 策略 B: 如果是 Root (0:0) 且 目录为空
# 这是 Docker 自动创建的新目录，我们把它“接管”过来，改成普通用户权限
if [ "$TARGET_UID" -eq 0 ] && [ "$TARGET_GID" -eq 0 ] && [ "$IS_EMPTY_DIR" = true ]; then
    echo "🆕 检测到全新的空目录。正在初始化权限为 1000:1000 ..."

    # 强制修改权限
    chown 1000:1000 $USER_HOME

    # 更新变量
    TARGET_UID=1000
    TARGET_GID=1000
else
    # 👇 策略 C: 非 Root 目录 (普通情况)
    echo "📂 使用现有目录权限: UID=$TARGET_UID"
fi


# --- 4. 清理与创建用户 ---
echo "🧹 清理旧用户环境 ..."
userdel -f $USER_NAME 2>/dev/null || true
groupdel $USER_NAME 2>/dev/null || true
sleep 0.1

echo "🔧 创建用户 $USER_NAME (最终 UID: $TARGET_UID) ..."
groupadd -g $TARGET_GID $USER_NAME
useradd -u $TARGET_UID -g $USER_NAME -o -m -d $USER_HOME -s /bin/bash $USER_NAME

# --- 5. 配置 ---
echo "🔒 设置密码 ..."
echo "$USER_NAME:$USER_PASS" | chpasswd
echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 确保权限一致
chown $TARGET_UID:$TARGET_GID $USER_HOME

# --- 6. 放置配置文件 ---
CONFIG_FILE="$USER_HOME/.xsession"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 创建 .xsession 配置 ..."
    echo "xfce4-session" > "$CONFIG_FILE"
    chown $TARGET_UID:$TARGET_GID "$CONFIG_FILE"
fi



# 逻辑：
# 1. 输入密码 (设置控制密码)
# 2. 输入密码 (设置查看密码 - 虽然我们要拒绝它，但 vncpasswd 会先问)
# 3. 输入 'n' (拒绝设置查看密码)
VNC_PASS=${VNC_PASS:-123456}
x11vnc -storepasswd "$VNC_PASS" /tmp/vnc.passwd

# 修改权限
chown $TARGET_UID:$TARGET_GID /tmp/vnc.passwd
chmod 600 /tmp/vnc.passwd

# 添Desktop添加桌面快捷方式
su - app -c "mkdir ~/Desktop/ && cp /usr/Desktop/* ~/Desktop/"

# --- 6. 启动 ---
echo "✅ 启动服务 ..."
# 创建普通用户日志目录
mkdir -p /config/logs/supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf