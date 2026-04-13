# 创建使用用户, 配置密码
sh ./create_user.sh

# 添加gpu驱动组
sh ./create_groups.sh

# --- 6. 启动 ---
echo "✅ 启动服务 ..."
# 创建普通用户日志目录
mkdir -p /config/logs/supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf