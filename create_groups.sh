#!/bin/bash

setup_gpu_groups() {
    local USER_NAME=${USER_NAME:-appuser}
    local CARD_DEV="/dev/dri/card0"
    local RENDER_DEV="/dev/dri/renderD128"

    # 1. 检查设备是否存在
    if [ ! -e "$CARD_DEV" ] || [ ! -e "$RENDER_DEV" ]; then
        echo "⚠️ 警告: GPU 设备未挂载 ($CARD_DEV 或 $RENDER_DEV 不存在)。"
        echo "   跳过 GPU 组配置，正常退出。"
        return 0 # 正常退出，不报错
    fi

    # 2. 获取 GID
    local CARD_GID=$(stat -c '%g' "$CARD_DEV")
    local RENDER_GID=$(stat -c '%g' "$RENDER_DEV")

    # 防御性编程：如果stat失败
    if [ -z "$CARD_GID" ] || [ -z "$RENDER_GID" ]; then
        echo "❌ 错误: 无法读取设备 GID。"
        return 0
    fi

    echo "ℹ️ 检测到 GPU 设备组 ID: card0=$CARD_GID, renderD128=$RENDER_GID"

    # 3. 根据 GID 是否相同执行逻辑
    if [ "$CARD_GID" -eq "$RENDER_GID" ]; then
        # --- 情况 A: GID 相同 ---
        # 统一使用 video 组
        local TARGET_GID=$CARD_GID
        local GROUP_NAME="video"

        # 检查组是否存在
        if ! getent group "$GROUP_NAME" > /dev/null; then
            echo "👉 创建组 $GROUP_NAME (GID: $TARGET_GID)"
            groupadd -g "$TARGET_GID" "$GROUP_NAME"
        else
            # 组存在但 GID 不对，尝试修改
            local EXISTING_GID=$(getent group "$GROUP_NAME" | cut -d: -f3)
            if [ "$EXISTING_GID" -ne "$TARGET_GID" ]; then
                echo "👉 修改现有组 $GROUP_NAME 的 GID 为 $TARGET_GID"
                groupmod -g "$TARGET_GID" "$GROUP_NAME"
            fi
        fi

        # 将用户加入组
        usermod -aG "$GROUP_NAME" "$USER_NAME"
        echo "✅ 用户 $USER_NAME 已加入组 $GROUP_NAME"

    else
        # --- 情况 B: GID 不同 ---
        # 分别创建 video 和 render 组

        # 处理 video 组
        if ! getent group video > /dev/null; then
            echo "👉 创建组 video (GID: $CARD_GID)"
            groupadd -g "$CARD_GID" video
        else
            # 检查 GID 是否匹配
            local EXISTING_GID=$(getent group video | cut -d: -f3)
            if [ "$EXISTING_GID" -ne "$CARD_GID" ]; then
                echo "👉 修正组 video 的 GID 为 $CARD_GID"
                groupmod -g "$CARD_GID" video
            fi
        fi
        usermod -aG video "$USER_NAME"

        # 处理 render 组
        if ! getent group render > /dev/null; then
            echo "👉 创建组 render (GID: $RENDER_GID)"
            groupadd -g "$RENDER_GID" render
        else
            # 检查 GID 是否匹配
            local EXISTING_GID=$(getent group render | cut -d: -f3)
            if [ "$EXISTING_GID" -ne "$RENDER_GID" ]; then
                echo "👉 修正组 render 的 GID 为 $RENDER_GID"
                groupmod -g "$RENDER_GID" render
            fi
        fi
        usermod -aG render "$USER_NAME"

        echo "✅ 用户 $USER_NAME 已加入组 video 和 render"
    fi
}

# 执行函数
setup_gpu_groups

# 脚本结束，返回 0 确保调用者不会报错
exit 0