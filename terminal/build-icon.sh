#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}"
stage=$(mktemp -d "${TMPDIR:-/tmp}/voztty-icon.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
mkdir "$stage/VozTTY.iconset"
magick -background none -depth 8 ../assets/voztty-icon.svg "$stage/master.png"
# The terminal glyph once disappeared during SVG conversion; check both filled shapes.
[[ $(magick "$stage/master.png" -format '%[hex:p{475,512}]' info:) == 111B22FF ]]
[[ $(magick "$stage/master.png" -format '%[hex:p{629,679}]' info:) == 111B22FF ]]
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$stage/master.png" --out "$stage/VozTTY.iconset/icon_${size}x${size}.png" >/dev/null
    retina=$((size * 2))
    sips -z "$retina" "$retina" "$stage/master.png" --out "$stage/VozTTY.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$stage/VozTTY.iconset" -o "$stage/VozTTY.icns"
sips -s format png "$stage/VozTTY.icns" --out "$stage/decoded.png" >/dev/null
[[ $(magick "$stage/decoded.png" -format '%[hex:p{475,512}]' info:) == 111B22FF ]]
cp "$stage/VozTTY.icns" VozTTY.icns
print "Built and checked: $PWD/VozTTY.icns"
