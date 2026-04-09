FROM debian:bookworm-slim

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

RUN apt-get update

# 2. 安装基础系统工具和依赖
# 这些是运行桌面和远程服务的基础，先安装它们
RUN apt-get install -y --no-install-recommends \
    curl \
    wget \
    xz-utils \
    supervisor \
    dbus-x11 \
    locales \
    ca-certificates

# 3. 安装中文字体
RUN apt-get install -y --no-install-recommends \
    fonts-wqy-zenhei \
    fonts-wqy-microhei

# 4. 安装 XFCE4 桌面环境
# 桌面环境比较大，单独一行，方便观察进度
RUN apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    xterm

# 5. 安装 GPU 驱动和远程桌面服务
# 驱动和 xrdp 放在最后
RUN apt-get install -y --no-install-recommends \
    intel-media-driver \
    vainfo \
    libmfx1 \
    xrdp \
    xorgxrdp

# 6. 清理缓存
# 分步执行后，最后统一清理，确保镜像体积最小
RUN rm -rf /var/lib/apt/lists/*

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