#!/bin/sh
# Scales the icon masters in build/icon (made by render_icon_test.dart) into
# the Android legacy + adaptive launcher icons and the iOS AppIcon set.
#   fvm flutter test tool/icon/render_icon_test.dart && sh tool/icon/make_icons.sh
set -e
cd "$(dirname "$0")/../.."
src=build/icon
res=android/app/src/main/res

scale() { # in out size [extra ffmpeg args]
  ffmpeg -y -loglevel error -i "$1" -vf "scale=$3:$3:flags=lanczos" $4 "$2"
}

for pair in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  dpi=${pair%%:*}; px=${pair##*:}
  layer=$((px * 9 / 4)) # adaptive layers are 108 dp against the 48 dp icon
  dir=$res/mipmap-$dpi
  mkdir -p "$dir"
  scale $src/icon_full.png "$dir/ic_launcher.png" "$px"
  scale $src/icon_foreground.png "$dir/ic_launcher_foreground.png" "$layer"
  scale $src/icon_background.png "$dir/ic_launcher_background.png" "$layer"
  scale $src/icon_monochrome.png "$dir/ic_launcher_monochrome.png" "$layer"
done

mkdir -p $res/mipmap-anydpi-v26
cat > $res/mipmap-anydpi-v26/ic_launcher.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
XML

# iOS: opaque squares (iOS rounds the corners itself).
ios=ios/Runner/Assets.xcassets/AppIcon.appiconset
for f in "$ios"/Icon-App-*.png; do
  name=$(basename "$f" .png)            # Icon-App-83.5x83.5@2x
  pt=${name#Icon-App-}; pt=${pt%%x*}    # 83.5
  mul=${name##*@}; mul=${mul%x}         # 2
  px=$(awk "BEGIN { printf \"%d\", $pt * $mul + 0.5 }")
  scale $src/icon_square.png "$f" "$px" "-pix_fmt rgb24"
done
# Web: the rounded icon, and the adaptive layers flattened for "maskable".
web=web/icons
scale $src/icon_full.png web/favicon.png 32
scale $src/icon_full.png $web/Icon-192.png 192
scale $src/icon_full.png $web/Icon-512.png 512
for px in 192 512; do
  ffmpeg -y -loglevel error -i $src/icon_background.png -i $src/icon_foreground.png \
    -filter_complex "[0][1]overlay,scale=$px:$px:flags=lanczos" $web/Icon-maskable-$px.png
done
echo "icons written"
