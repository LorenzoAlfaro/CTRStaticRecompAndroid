# CTR Static Recomp — Android

Android build of [CTRStaticRecomp](https://github.com/LorenzoAlfaro/CTRStaticRecomp), the static
recompilation of Crash Team Racing (PS1, USA, SCUS-94426). The recompiled game code and the
runtime are the same as on Windows; this project packages them as an APK (arm64-v8a) with SDL2's
Android glue, built with the SDK/NDK tools directly (no Gradle).

**No game code or data is included.** The APK contains code recompiled from your own disc, so it
is for personal use only and must not be distributed.

## Status

* Tested on a Pixel 7a (Android 17): boots to the menus at full speed (60 fps) at 2x internal
  resolution with PGXP.
* Fills the whole screen (widescreen at the phone's own aspect, 20:9 on a Pixel 7a) with the
  emulated CPU at 200% so the wider view doesn't cost game frames.
* Input: game controllers over USB or Bluetooth (SDL mappings). Click the left stick to cycle
  4:3 / 16:9 / fill and the right stick to cycle 1x / 2x / 4x. No touch controls yet.
* Settings, memory cards and the log (`ctr.log`) live next to the disc image in the app folder.

## Building

1. Build [CTRStaticRecomp](https://github.com/LorenzoAlfaro/CTRStaticRecomp) once on Windows with
   `build.ps1 -Disc ...`, in a folder next to this one (`..\CTRStaticRecomp`). That extracts the
   game code into `..\CTRStaticRecomp\data`.
2. Install Android Studio (for the SDK, platform-tools and its bundled JDK), then the NDK and
   CMake: `sdkmanager "ndk;29.0.14206865" "cmake;3.31.6"`.
3. `pwsh .\build.ps1 -Install` builds `ctr-recomp.apk` and installs it over USB debugging.

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

## License

MIT, like CTRStaticRecomp. SDL2 (zlib license) and its Java glue are downloaded at build time.
