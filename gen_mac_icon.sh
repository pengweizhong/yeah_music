#!/bin/bash
# 一键生成 macOS AppIcon，圆角 + 透明边距 + iconset + Contents.json + icns

ICON_SRC="yeah_music.png"
ICONSET_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"
TMP_DIR="./temp/icon"

# 清理旧 iconset 和临时文件夹
rm -rf $ICONSET_DIR $TMP_DIR
mkdir -p $ICONSET_DIR $TMP_DIR


echo "增加透明边距..."
# extent 越大 → 图标内容越小 (1280-1024)/1280 ≈ 20% 这里设置的缩小5%
magick $ICON_SRC -resize 1024x1024 \
  -background none -gravity center -extent 1078x1078 \
  $TMP_DIR/year_music_padded.png

echo "生成各尺寸图标..."
sizes=(
  "icon_16x16.png 16"
  "icon_16x16@2x.png 32"
  "icon_32x32.png 32"
  "icon_32x32@2x.png 64"
  "icon_128x128.png 128"
  "icon_128x128@2x.png 256"
  "icon_256x256.png 256"
  "icon_256x256@2x.png 512"
  "icon_512x512.png 512"
  "icon_512x512@2x.png 1024"
)

for entry in "${sizes[@]}"; do
  set -- $entry
  filename=$1
  size=$2
  magick $TMP_DIR/year_music_padded.png -resize ${size}x${size} $ICONSET_DIR/$filename
done

echo "生成 Contents.json..."
cat > $ICONSET_DIR/Contents.json <<EOL
{
  "images": [
    { "idiom": "mac", "size": "16x16", "scale": "1x", "filename": "icon_16x16.png" },
    { "idiom": "mac", "size": "16x16", "scale": "2x", "filename": "icon_16x16@2x.png" },
    { "idiom": "mac", "size": "32x32", "scale": "1x", "filename": "icon_32x32.png" },
    { "idiom": "mac", "size": "32x32", "scale": "2x", "filename": "icon_32x32@2x.png" },
    { "idiom": "mac", "size": "128x128", "scale": "1x", "filename": "icon_128x128.png" },
    { "idiom": "mac", "size": "128x128", "scale": "2x", "filename": "icon_128x128@2x.png" },
    { "idiom": "mac", "size": "256x256", "scale": "1x", "filename": "icon_256x256.png" },
    { "idiom": "mac", "size": "256x256", "scale": "2x", "filename": "icon_256x256@2x.png" },
    { "idiom": "mac", "size": "512x512", "scale": "1x", "filename": "icon_512x512.png" },
    { "idiom": "mac", "size": "512x512", "scale": "2x", "filename": "icon_512x512@2x.png" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
EOL

echo "生成 icns 文件..."
iconutil -c icns $ICONSET_DIR

# 可选：清理临时文件夹
rm -rf $TMP_DIR

echo "完成！"
