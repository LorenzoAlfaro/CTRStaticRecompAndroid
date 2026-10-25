#!/bin/sh
# Scripted two-player VS race (split screen) on a device: profile lines and a screenshot.
#   sh tools/tv2p.sh DEVICE SCALE OUT.bmp
export MSYS_NO_PATHCONV=1  # Git Bash: keep device paths as they are
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
DEV=$1; SCALE=$2; OUT=$3
PKG=io.github.lorenzoalfaro.ctrrecomp
DIR=/sdcard/Android/data/$PKG/files
KEYS="2700:down,2740:down,2780:down"
f=2840
for i in $(seq 0 15); do KEYS="$KEYS,$f:cross+p2.cross"; f=$((f + 60)); done
KEYS="$KEYS,3900:cross+p2.cross:3000"
"$ADB" -s "$DEV" shell am force-stop $PKG
"$ADB" -s "$DEV" shell "am start -n $PKG/.CTRActivity -e args '--turbo --profile --players 2 --renderer gl --aspect 4:3 --overclock 400 --scale $SCALE --frames 6000 --shot 5400 $DIR/vs2.bmp --keys $KEYS'" > /dev/null
start=$(date +%s)
while "$ADB" -s "$DEV" shell pidof $PKG > /dev/null; do
    sleep 3
    [ $(( $(date +%s) - start )) -gt 600 ] && break
done
echo "--- two players, scale $SCALE: $(( $(date +%s) - start )) s"
"$ADB" -s "$DEV" shell cat $DIR/ctr.log | grep -E "player 2|profile: [0-9]|game renders|GL thread" | tail -13 | sed -e 's/stalls.*//' -e 's/, [0-9]* jobs.*//'
"$ADB" -s "$DEV" pull $DIR/vs2.bmp "$OUT" > /dev/null
