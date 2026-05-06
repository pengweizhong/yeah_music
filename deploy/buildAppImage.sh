#!/bin/bash
set -e

# ====================== 【配置区域】======================
APP_NAME="YeahMusic"         # 应用名
# VERSION="1.0.0"           # 已注释，自动从 pubspec.yaml 读取
ARCH="x86_64"                # 系统架构
ICON_NAME="yeah_music"       # 图标名
EXEC_NAME="yeah_music"       # 可执行文件名
# ==========================================================

# 定位到项目根目录
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

cd "$PROJECT_ROOT" || exit 1

# 读取版本号（从 pubspec.yaml）
VERSION=$(grep 'version:' pubspec.yaml | head -n1 | awk '{print $2}' | cut -d'+' -f1)
echo "🚀 当前版本号：$VERSION (自动从 pubspec.yaml 读取)"

# 清理 + 构建
flutter clean
flutter build linux --release

# 清理旧目录
rm -rf AppDir
rm -f "${APP_NAME}-${VERSION}-${ARCH}.AppImage"

# 创建目录结构
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/lib
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps

# 复制构建产物
BUNDLE_DIR="build/linux/x64/release/bundle"
cp -r "$BUNDLE_DIR"/* AppDir/usr/bin/

# 复制图标
cp ${ICON_NAME}.png AppDir/usr/share/icons/hicolor/256x256/apps/${ICON_NAME}.png
cp ${ICON_NAME}.png AppDir/

# 生成 desktop 文件
cat > AppDir/${ICON_NAME}.desktop << EOF
[Desktop Entry]
Name=Yeah Music
Comment=Yeah Music 是一个基于 Flutter 开发的跨平台音乐应用
Exec=${EXEC_NAME}
Icon=${ICON_NAME}
Terminal=false
Type=Application
Categories=AudioVideo;Player;Music;
StartupWMClass=${ICON_NAME}
EOF

cp AppDir/${ICON_NAME}.desktop AppDir/usr/share/applications/

# 生成 AppRun
cat > AppDir/AppRun << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:$LD_LIBRARY_PATH"
exec "$HERE/usr/bin/yeah_music" "$@"
EOF

# 权限修复
chmod -R 755 AppDir
chmod +x AppDir/AppRun
chmod +x AppDir/usr/bin/${EXEC_NAME}

# 下载打包工具
if [ ! -f appimagetool ]; then
  wget -O appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool
fi

# 打包
./appimagetool AppDir ${APP_NAME}-${VERSION}-${ARCH}.AppImage
chmod +x ${APP_NAME}-${VERSION}-${ARCH}.AppImage

echo -e "\n✅ 打包完成！"
echo "▶  运行命令：./${APP_NAME}-${VERSION}-${ARCH}.AppImage"