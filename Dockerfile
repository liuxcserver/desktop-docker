# 基础环境
FROM debian:bookworm-slim

# 设置时区和语言
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------------------------------------------------
# 更新apt list
RUN apt-get update

# 安装桌面环境 + 关键图形库
RUN apt-get install -y \
    # 桌面环境
    xfce4 xfce4-goodies  \
    # 字体和终端
    xterm fonts-wqy-zenhei \
    # 远程服务
    xrdp x11vnc novnc websockify \
    # --- 关键图形库开始 ---
    libgl1-mesa-dri libgbm1 mesa-va-drivers
    # --- 关键图形库结束 ---

# 工具
RUN apt-get install -y supervisor sudo

# 生成中文 Locale (解决语言环境变量报错)
# --- 修复中文 Locale 支持 ---
# 1. 先安装 locales 包 (很多精简镜像默认不带这个命令)
RUN apt-get install -y locales && \
    # 2. 强制生成 zh_CN.UTF-8 (不管原文件里有没有这行,直接生成)
    locale-gen zh_CN.UTF-8 && \
    # 3. 更新系统默认配置
    update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh

# 移除apt list缓存
RUN rm -rf /var/lib/apt/lists/*

# todo 安装115网盘 + telegram

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389 6080

CMD ["/entrypoint.sh"]