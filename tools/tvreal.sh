#!/bin/sh
# Real-time (no --turbo) scripted race on a device: the profile lines that show stutter.
#   sh tools/tvreal.sh DEVICE "OPTIONS" [FRAMES]
export MSYS_NO_PATHCONV=1  # Git Bash: keep device paths as they are
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
DEV=$1; OPTS=$2; FRAMES=${3:-5400}
PKG=io.github.lorenzoalfaro.ctrrecomp
DIR=/sdcard/Android/data/$PKG/files
# skip the intros, arcade race on Crash Cove (as tools/bench.ps1), using items
KEYS=""
for i in $(seq 0 43); do KEYS="$KEYS$((150 + i * 40)):start,"; done
KEYS="${KEYS}2300:down,2340:down,"
for i in $(seq 0 13); do KEYS="$KEYS$((2380 + i * 60)):cross,"; done
KEYS="${KEYS}3300:cross:9000"
# fire the item every 1.5 s once racing: the kart picks one up at the first boxes, and rivals'
# weapons explode around it (item, missile and explosion sound effects)
for i in $(seq 0 50); do KEYS="$KEYS,$((4300 + i * 90)):circle"; done
"$ADB" -s "$DEV" shell am force-stop $PKG
"$ADB" -s "$DEV" shell "am start -n $PKG/.CTRActivity -e args '--profile $OPTS --frames $FRAMES --keys $KEYS'" > /dev/null
start=$(date +%s)
while "$ADB" -s "$DEV" shell pidof $PKG > /dev/null; do
    sleep 3
    [ $(( $(date +%s) - start )) -gt 600 ] && break
done
echo "--- $OPTS: $(( $(date +%s) - start )) s"
"$ADB" -s "$DEV" shell cat $DIR/ctr.log | grep -E "profile: [0-9]|real time|GL thread" | tail -${TAIL:-9} | sed -e 's/stalls.*//' -e 's/, [0-9]* jobs.*//' -e 's/.*profile: //'
