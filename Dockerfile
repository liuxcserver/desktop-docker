# 基础环境
FROM debian:bookworm-slim

# 设置时区和语言
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

#--------------------------------------------------------------------------------------------------------------------
# 安装最新显卡驱动
# 1. 添加 Trixie 源到 sources.list
# 注意：在 Docker 中直接 echo 到 /etc/apt/sources.list 是最快的方法
RUN echo "deb http://deb.debian.org/debian trixie main" > /etc/apt/sources.list.d/trixie.list
# 2. 设置 APT Pinning (优先级)
RUN echo -e "Package: *\nPin: release n=trixie\nPin-Priority: 50" > /etc/apt/preferences.d/trixie
# 3.更新索引并从 Trixie 安装新版驱动和依赖
# 我们把驱动、vainfo 和核心库一起列出来，确保版本匹配
RUN apt-get update && \
    apt-get install -y --no-install-recommends -t trixie \
    intel-media-va-driver \
    libva2 \
    libva-drm2 \
    libva-x11-2 \
    libva-wayland2 \
    && rm -rf /var/lib/apt/lists/*
#--------------------------------------------------------------------------------------------------------------------

# 更新apt list
RUN apt-get update
# 安装桌面环境 + 关键图形库
RUN apt-get install -y --no-install-recommends \
    # 桌面环境
    xfce4 xfce4-goodies xvfb \
    # 字体和终端
    xterm fonts-wqy-zenhei \
    # 远程服务
    x11vnc dbus-x11 \
    # --- 关键图形库开始 ---
    libgl1-mesa-dri libgbm1 libpam-systemd
    # --- 关键图形库结束 ---
# 工具
RUN apt-get install -y --no-install-recommends supervisor sudo wget ca-certificates unzip curl xz-utils

RUN wget -O /tmp/noVNC.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip
RUN wget -O /tmp/websockify.zip https://github.com/novnc/websockify/archive/refs/heads/master.zip

# 解压
RUN mkdir -p /usr/share/noVNC /usr/share/websockify

RUN unzip /tmp/noVNC.zip -d /usr/share/noVNC
RUN mv /usr/share/noVNC/noVNC-master/* /usr/share/noVNC/
RUN rm -rf /usr/share/noVNC/noVNC-master

RUN unzip  /tmp/websockify.zip -d /usr/share/websockify
RUN mv /usr/share/websockify/websockify-master/* /usr/share/websockify/
RUN rm -rf /usr/share/websockify/websockify-master

RUN mv /usr/share/websockify /usr/share/noVNC/utils/websockify

# 生成中文 Locale (解决语言环境变量报错)
# --- 修复中文 Locale 支持 ---
# 1. 先安装 locales 包 (很多精简镜像默认不带这个命令)
RUN apt-get install -y --no-install-recommends locales
RUN echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
ENV LANG=zh_CN.UTF-8

# todo 安装115网盘 + telegram
RUN curl -o /tmp/telegram.tar.xz https://td.telegram.org/tlinux/tsetup.6.7.5.tar.xz
RUN mkdir -p /usr/telegram
RUN tar -xJvf /tmp/telegram.tar.xz -C /usr

RUN curl -o /tmp/115.deb https://down.115.com/client/115pc/lin/115br_v36.0.0.deb
RUN apt-get install -y --no-install-recommends libnss3 libasound2
RUN apt install -y /tmp/115.deb

# 移除apt list缓存
RUN apt-get remove -y wget unzip curl xz-utils
RUN apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/*

# 软件图标
RUN mkdir -p /usr/ico
RUN mkdir -p /usr/Desktop
COPY ico/* /usr/ico
COPY Desktop/* /usr/Desktop

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY create_groups.sh /create_groups.sh
COPY create_user.sh /create_user.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389 6080

CMD ["/entrypoint.sh"]