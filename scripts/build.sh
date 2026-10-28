#!/bin/zsh
# Builds build/LayoutFixer.app (and build/LayoutFixer-macOS.zip with --zip).
# The version comes from $VERSION when set (the release workflow passes the tag).
set -e
cd "$(dirname "$0")/.."
VERSION=${VERSION:-0.2.0}
APP=build/LayoutFixer.app
rm -rf $APP
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
cp Resources/* $APP/Contents/Resources/
cat > $APP/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>io.github.layoutfixer</string>
  <key>CFBundleName</key><string>LayoutFixer</string>
  <key>CFBundleDisplayName</key><string>LayoutFixer</string>
  <key>CFBundleExecutable</key><string>LayoutFixer</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict></plist>
PLIST
# Universal binary: Apple silicon and Intel.
for ARCH in arm64 x86_64; do
  swiftc -O -target $ARCH-apple-macos13.0 Sources/main.swift -o build/LayoutFixer-$ARCH \
    -framework Cocoa -framework Carbon
done
lipo -create build/LayoutFixer-arm64 build/LayoutFixer-x86_64 -output $APP/Contents/MacOS/LayoutFixer
rm build/LayoutFixer-arm64 build/LayoutFixer-x86_64
xattr -cr $APP
codesign --force --sign - $APP
if [[ "$1" == "--zip" ]]; then
  rm -f build/LayoutFixer-macOS.zip
  (cd build && ditto -c -k --norsrc --noextattr --keepParent LayoutFixer.app LayoutFixer-macOS.zip)
  echo "built build/LayoutFixer-macOS.zip"
fi
echo "built $APP"
