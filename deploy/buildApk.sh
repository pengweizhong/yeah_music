#!/bin/bash
set -e

# ====================== 【配置区域】======================
APP_NAME="YeahMusic"         # 应用名
PLATFORM="android"           # 平台名称
ARCH="arm64"                 # 架构
# ==========================================================

# ====================== 接收命令行参数 ======================
if [ $# -ne 1 ]; then
    echo "❌ 用法：$0 <ONEDRIVE_CLIENT_ID>"
    echo "示例：$0 00000000-0000-0000-0000-000000000000"
    exit 1
fi

ONEDRIVE_CLIENT_ID="$1"
DART_DEFINES="--dart-define=ONEDRIVE_CLIENT_ID=${ONEDRIVE_CLIENT_ID}"

# 定位到项目根目录
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

cd "$PROJECT_ROOT" || exit 1

# 读取版本号（从 pubspec.yaml）
VERSION=$(grep 'version:' pubspec.yaml | head -n1 | awk '{print $2}' | cut -d'+' -f1)
echo "🚀 当前版本号：$VERSION (自动从 pubspec.yaml 读取)"
echo "🔑 ONEDRIVE_CLIENT_ID 已通过命令行传入"

# 输出文件名（你要的格式）
APK_OUTPUT="${APP_NAME}-${PLATFORM}-${ARCH}-${VERSION}.apk"

# 清理 + 构建 Android
echo "🔨 构建 ${PLATFORM} ${ARCH} APK..."
flutter clean
flutter build apk --release ${DART_DEFINES}

# 复制并重命名
cp -f build/app/outputs/flutter-apk/app-release.apk "${APK_OUTPUT}"

echo -e "\n✅ 打包完成！"
echo "▶  生成文件：${APK_OUTPUT}"