FROM debian:bookworm-slim

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 1. 优化软件源配置 (针对 GitHub Actions 环境优化)
# GitHub Actions 连接 Debian 官方源通常很快，但为了防止 SSL 错误或偶发断连，
# 我们保留官方源，但增加 apt 配置以禁用严格的安全检查（仅在构建时），并增加重试。
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    apt-get update -o Acquire::https::AllowInsecure=true && \
    apt-get install -y --no-install-recommends \
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

# 3. 安装 KasmVNC (增加重试逻辑)
# GitHub Actions 下载外部文件偶尔会超时，使用循环重试
RUN for i in 1 2 3; do \
        wget -qO - https://www.kasmweb.com/downloads/vnc/debian/kasmvnc_debian_bookworm_1.3.0_amd64.deb -O /tmp/kasmvnc.deb && break || sleep 5; \
    done && \
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