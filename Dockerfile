# 基础环境
FROM debian:bookworm-slim

# 设置时区和语言
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------------------------------------------------
# 更新apt list
RUN apt-get update
# 安装桌面环境 + 关键图形库
RUN apt-get install -y --no-install-recommends \
    # 桌面环境
    xfce4 xfce4-goodies xvfb \
    # 字体和终端
    xterm fonts-wqy-zenhei \
    # 远程服务
    xrdp x11vnc \
    # --- 关键图形库开始 ---
    libgl1-mesa-dri libgbm1 mesa-va-drivers
    # --- 关键图形库结束 ---
# 工具
RUN apt-get install -y --no-install-recommends supervisor sudo wget ca-certificates

RUN wget -O /tmp/noVNC.tar.gz https://github.com/novnc/noVNC/archive/refs/tags/v1.6.0.tar.gz
RUN wget -O /tmp/websockify.tar.gz https://github.com/novnc/websockify/archive/refs/tags/v0.13.0.tar.gz

# 解压
RUN mkdir -p /usr/share/noVNC /usr/share/websockify
RUN tar -xzf /tmp/noVNC.tar.gz -C /usr/share/noVNC --strip-components=1
RUN tar -xzf /tmp/websockify.tar.gz -C /usr/share/websockify --strip-components=1
RUN mv /usr/share/websockify /usr/share/novnc/utils/websockify

# 生成中文 Locale (解决语言环境变量报错)
# --- 修复中文 Locale 支持 ---
# 1. 先安装 locales 包 (很多精简镜像默认不带这个命令)
RUN apt-get install -y --no-install-recommends locales
RUN echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
ENV LANG=zh_CN.UTF-8
# 移除apt list缓存
RUN apt-get remove -y wget && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/*.tar.gz

# todo 安装115网盘 + telegram

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389 6080

CMD ["/entrypoint.sh"]