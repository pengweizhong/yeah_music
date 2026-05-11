#!/bin/bash
set -e

# ====================== 【可配置区域】======================
APP_NAME="YeahMusic"
ARCH="amd64"
EXEC_NAME="yeah_music"
ICON_NAME="yeah_music"
INSTALL_DIR_NAME="yeah_music"
MAINTAINER="PengWeiZhong"
# ==========================================================

# ====================== 接收参数 ======================
if [ $# -ne 1 ]; then
    echo "❌ 用法：$0 <ONEDRIVE_CLIENT_ID>"
    echo "示例：$0 00000000-0000-0000-0000-000000000000"
    exit 1
fi

ONEDRIVE_CLIENT_ID="$1"
DART_DEFINES="--dart-define=ONEDRIVE_CLIENT_ID=${ONEDRIVE_CLIENT_ID}"

# ====================== 定位目录 ======================
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
cd "$PROJECT_ROOT" || exit 1

# 自动读取版本号
VERSION=$(grep 'version:' pubspec.yaml | head -n1 | awk '{print $2}' | cut -d'+' -f1)
echo "🚀 当前版本：$VERSION (从 pubspec.yaml 自动读取)"
echo "🔑 ONEDRIVE_CLIENT_ID 已通过命令行传入"

DEB_OUTPUT="${APP_NAME}-${ARCH}-${VERSION}.deb"

# 构建 Flutter（带环境变量）
echo "🔨 构建 Flutter Linux..."
flutter clean
flutter build linux --release ${DART_DEFINES}

# 清理旧包
rm -rf deb_build
rm -f "${DEB_OUTPUT}"

# 目录结构
mkdir -p deb_build/DEBIAN
mkdir -p deb_build/opt/${INSTALL_DIR_NAME}
mkdir -p deb_build/usr/bin
mkdir -p deb_build/usr/share/applications
mkdir -p deb_build/usr/share/icons/hicolor/256x256/apps

echo "📦 复制程序文件..."
cp -r build/linux/x64/release/bundle/* deb_build/opt/${INSTALL_DIR_NAME}/

# 国际化
if [ -d "assets/l10n" ]; then
  echo "🌍 复制国际化文件..."
  mkdir -p deb_build/opt/${INSTALL_DIR_NAME}/assets/l10n
  cp -r assets/l10n/* deb_build/opt/${INSTALL_DIR_NAME}/assets/l10n/
fi

# 图标
cp "${ICON_NAME}.png" deb_build/usr/share/icons/hicolor/256x256/apps/${ICON_NAME}.png

# desktop 文件
cat > deb_build/usr/share/applications/${ICON_NAME}.desktop << EOF
[Desktop Entry]
Name=Yeah Music
Comment=Yeah Music 是一个基于 Flutter 开发的跨平台音乐应用
Exec=/opt/${INSTALL_DIR_NAME}/${EXEC_NAME}
Icon=${ICON_NAME}
Terminal=false
Type=Application
Categories=AudioVideo;Player;Music;
StartupWMClass=${EXEC_NAME}
EOF

# 软链接
ln -s /opt/${INSTALL_DIR_NAME}/${EXEC_NAME} deb_build/usr/bin/${EXEC_NAME}

# control
cat > deb_build/DEBIAN/control << EOF
Package: yeah-music
Version: ${VERSION}
Section: sound
Priority: optional
Architecture: ${ARCH}
Maintainer: ${MAINTAINER}
Depends: libgtk-3-0, libc6
Description: Yeah Music 是一个基于 Flutter 开发的跨平台音乐应用
EOF

# 权限
chmod -R 755 deb_build/opt/${INSTALL_DIR_NAME}
chmod 755 deb_build/DEBIAN
chmod 644 deb_build/DEBIAN/control

# 打包
echo "📦 生成 ${DEB_OUTPUT}"
dpkg-deb --build deb_build "${DEB_OUTPUT}"

echo -e "\n✅ 打包完成！"
echo "安装：sudo dpkg -i ${DEB_OUTPUT}"
echo "卸载：sudo dpkg -r yeah-music"