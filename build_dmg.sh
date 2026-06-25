#!/bin/bash
set -e

echo "🔨 Собираем MacMon..."

xcodebuild -project MacMon.xcodeproj \
           -scheme MacMon \
           -configuration Release \
           -derivedDataPath build \
           build

APP_PATH="build/Build/Products/Release/MacMon.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Сборка не удалась — .app не найден"
    exit 1
fi

echo "📦 Создаём DMG..."
rm -f MacMon.dmg MacMon.rw.dmg

STAGE="build/dmg_staging"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -volname "MacMon" \
               -srcfolder "$STAGE" \
               -ov -format UDRW \
               MacMon.rw.dmg

MOUNT_DIR="$(hdiutil attach MacMon.rw.dmg -nobrowse -noverify -noautoopen | grep "/Volumes/" | sed 's/.*\(\/Volumes\/.*\)/\1/')"

osascript <<EOF 2>/dev/null || true
tell application "Finder"
    tell disk "MacMon"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 700, 460}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 110
        set position of item "MacMon.app" of container window to {130, 160}
        set position of item "Applications" of container window to {370, 160}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

sync
hdiutil detach "$MOUNT_DIR" -quiet
hdiutil convert MacMon.rw.dmg -format UDZO -ov -o MacMon.dmg >/dev/null
rm -f MacMon.rw.dmg
rm -rf "$STAGE"

echo "✅ Готово: MacMon.dmg"
echo "   Размер: $(du -sh MacMon.dmg | cut -f1)"
