FROM debian:bookworm-slim

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 1. 优化软件源配置 (针对 GitHub Actions 环境优化)
# GitHub Actions 连接 Debian 官方源通常很快，但为了防止 SSL 错误或偶发断连，
# 我们增加 apt 配置以禁用严格的安全检查（仅在构建时），并增加重试。
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    apt-get update -o Acquire::https::AllowInsecure=true

# 2. 安装基础系统工具和依赖
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
RUN apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    xterm

# 5. 安装 GPU 驱动和远程桌面服务
# 这一步最容易失败，我们给它单独加一个重试循环
RUN for i in 1 2 3; do \
        apt-get install -y --no-install-recommends \
        intel-media-driver \
        vainfo \
        libmfx1 \
        xrdp \
        xorgxrdp && break || sleep 10; \
    done

# 6. 清理缓存
RUN rm -rf /var/lib/apt/lists/*

# 3. 编译安装 KasmVNC (使用源码)
# 这种方式比下载 deb 包更稳定
WORKDIR /tmp
RUN git clone --depth 1 --branch v1.3.0 https://github.com/kasmtech/KasmVNC.git kasmvnc && \
    cd kasmvnc && \
    mkdir build && cd build && \
    cmake .. -DENABLE_GNUTLS=ON -DENABLE_XORG=DONOT -DENABLE_JPEG=ON && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf kasmvnc

# 8. 复制配置文件
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

# 9. 设置权限
RUN chmod +x /start.sh

# 10. 暴露端口
EXPOSE 5900 3389 6901

# 启动命令
CMD ["/start.sh"]