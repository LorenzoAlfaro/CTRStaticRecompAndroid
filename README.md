# CTR Static Recomp — Android

Android build of [CTRStaticRecomp](https://github.com/LorenzoAlfaro/CTRStaticRecomp), the static
recompilation of Crash Team Racing (PS1, USA, SCUS-94426). The recompiled game code and the
runtime are the same as on Windows; this project packages them as an APK (arm64-v8a and
armeabi-v7a) with SDL2's Android glue, built with the SDK/NDK tools directly (no Gradle). It runs
on phones and on Android TV.

**No game code or data is included.** The APK contains code recompiled from your own disc, so it
is for personal use only and must not be distributed.

## Status

* **Android TV:** a Sony BRAVIA (MediaTek MT9687: four Cortex-A55 cores, Mali-G52, 32-bit Android)
  runs races at 2x internal resolution in 16:9 at full speed, about 11 ms per frame (16.7 is full
  speed). It shows up in the TV launcher (leanback entry and banner).
* **Phones:** tested on a Pixel 7a.
* **Defaults:** 2x internal resolution, filling the screen (widescreen at the display's own
  aspect), the OpenGL ES renderer, and the emulated CPU at 400% so busy scenes keep full speed.
* **Input:** game controllers over USB or Bluetooth (SDL mappings); a second controller is
  player 2 (VS. and Battle in split screen), and a TV remote never counts as a player. Click the
  left stick to cycle 4:3 / 16:9 / fill and the right stick to switch 1x / 2x. Hold Back on the
  remote for a second to quit. No touch controls yet.
* Settings, memory cards and the log (`ctr.log`) live next to the disc image in the app folder.

## Building

1. Build [CTRStaticRecomp](https://github.com/LorenzoAlfaro/CTRStaticRecomp) once on Windows with
   `build.ps1 -Disc ...`, in a folder next to this one (`..\CTRStaticRecomp`). That extracts the
   game code into `..\CTRStaticRecomp\data`.
2. Install Android Studio (for the SDK, platform-tools and its bundled JDK), then the NDK and
   CMake: `sdkmanager "ndk;29.0.14206865" "cmake;3.31.6"`.
3. `pwsh .\build.ps1 -Install` builds `ctr-recomp.apk` and installs it over USB debugging
   (`-Abis armeabi-v7a` builds only the 32-bit version for a TV, `-NoStrip` keeps symbols for
   profiling).

## Copying the disc

Start the app once so it creates its folder, then copy the `.cue` and `.bin` into it:

```
adb shell am start -n io.github.lorenzoalfaro.ctrrecomp/.CTRActivity
adb push "CTR - Crash Team Racing (USA).cue" "CTR - Crash Team Racing (USA).bin" /sdcard/Android/data/io.github.lorenzoalfaro.ctrrecomp/files/
```

The folder must be created by the app (not by `adb shell mkdir`), otherwise the app cannot read
it. Android's file manager can also copy files there on most devices.

## Testing from the PC

Command-line options can be passed through the launch intent, e.g. scripted input and verbose
logging (the log is `ctr.log` in the app folder):

```
adb shell "am start -n io.github.lorenzoalfaro.ctrrecomp/.CTRActivity -e args '-v --keys 300:start'"
```

Scripts in `tools/` (for an Android TV, connect over network debugging first: `adb connect <ip>:5555`):

* `bench.ps1`: a race in turbo mode, printing the per-frame profile.
* `tvreal.sh`: a race in real time that uses items, for stutter and audio dropouts.
* `tvshots.ps1`: the reference race with screenshots, compared with the PC build.
* `tv2p.sh`: a scripted two-player race.

`--input-log` logs what each controller presses.

## License

MIT, like CTRStaticRecomp. SDL2 (zlib license) and its Java glue are downloaded at build time.
