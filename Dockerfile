FROM debian:bookworm-slim

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 1. 安装基础软件包、桌面环境、中文字体、输入法、驱动
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xterm \
    locales \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    dbus-x11 \
    supervisor \
    curl \
    wget \
    xz-utils \
    # GPU 驱动 (Intel Media Driver for N150)
    intel-media-driver \
    vainfo \
    libmfx1 \
    # 远程桌面
    xrdp \
    xorgxrdp \
    && rm -rf /var/lib/apt/lists/*

# 2. 生成中文 Locale
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

# 3. 安装 KasmVNC (用于 Web 访问)
RUN wget -qO - https://www.kasmweb.com/downloads/vnc/debian/kasmvnc_debian_bookworm_1.3.0_amd64.deb -O /tmp/kasmvnc.deb && \
    dpkg -i /tmp/kasmvnc.deb && \
    rm /tmp/kasmvnc.deb

# 4. 复制配置文件
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

# 5. 设置权限
RUN chmod +x /start.sh

# 6. 暴露端口
EXPOSE 5900 3389 6901

# 启动命令
CMD ["/start.sh"]