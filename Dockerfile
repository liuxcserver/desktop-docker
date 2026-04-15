# 基础环境
FROM debian:bookworm-slim

# 设置时区和语言
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8

# ---------------------------------------------------------------------------------------------------------------------
# 安装桌面环境 + 关键图形库
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 桌面环境
    xfce4 xfce4-goodies xvfb \
    # 字体和终端
    xterm fonts-wqy-zenhei \
    # 远程服务
    x11vnc dbus-x11 \
    # --- 关键图形库开始 ---
    libgl1-mesa-dri libgbm1 libpam-systemd \
    # 工具
    supervisor sudo wget ca-certificates unzip curl xz-utils \
    # 语言
    locales \
    # 115依赖
    libnss3 libasound2

# 安装vnc相关
RUN wget -O /tmp/noVNC.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip && \
    wget -O /tmp/websockify.zip https://github.com/novnc/websockify/archive/refs/heads/master.zip && \
    mkdir -p /usr/share/noVNC /usr/share/websockify && \
    unzip /tmp/noVNC.zip -d /usr/share/noVNC && \
    mv /usr/share/noVNC/noVNC-master/* /usr/share/noVNC/ && \
    rm -rf /usr/share/noVNC/noVNC-master && \
    unzip  /tmp/websockify.zip -d /usr/share/websockify && \
    mv /usr/share/websockify/websockify-master/* /usr/share/websockify/ && \
    rm -rf /usr/share/websockify/websockify-master && \
    mv /usr/share/websockify /usr/share/noVNC/utils/websockify

# 生成中文 Locale (解决语言环境变量报错)
# --- 修复中文 Locale 支持 ---
RUN echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# 安装115网盘 + telegram
RUN curl -o /tmp/telegram.tar.xz https://td.telegram.org/tlinux/tsetup.6.7.6.tar.xz && \
    mkdir -p /usr/telegram && \
    tar -xJvf /tmp/telegram.tar.xz -C /usr && \
    curl -o /tmp/115.deb https://down.115.com/client/115pc/lin/115br_v36.0.0.deb && \
    apt install -y /tmp/115.deb

# 移除apt list缓存
RUN apt-get remove -y wget unzip curl xz-utils \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# 软件图标
RUN mkdir -p /usr/ico && mkdir -p /usr/Desktop
COPY ico/* /usr/ico
COPY Desktop/* /usr/Desktop

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389 6080

CMD ["/entrypoint.sh"]