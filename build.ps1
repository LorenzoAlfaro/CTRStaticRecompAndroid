# Build the Android APK: recompile the game code (from ../CTRStaticRecomp/data), compile it
# with the NDK into libmain.so next to libSDL2.so, compile SDL's Java glue, and package/sign
# the APK with the SDK build tools (no Gradle).
#   pwsh .\build.ps1 [-Install] [-Run]
# Requires: Android SDK (build-tools, platform, cmake), NDK, the JDK bundled with Android Studio,
# Python 3, and a CTRStaticRecomp checkout next to this folder that has been built once with
# its own build.ps1 -Disc (which extracts the game code into ../CTRStaticRecomp/data).
param(
    [switch]$Install,
    [switch]$Run,
    [string]$Sdk = "$env:LOCALAPPDATA\Android\Sdk",
    [string]$NdkVersion = "29.0.14206865",
    [string]$CMakeVersion = "3.31.6",
    [string]$BuildTools = "36.0.0",
    [string]$Platform = "android-36",
    [string]$Jdk = "C:\Program Files\Android\Android Studio\jbr",
    [string[]]$Abis = @("arm64-v8a", "armeabi-v7a"),
    [switch]$NoStrip  # keep symbols (for profiling with simpleperf)
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$Package = "io.github.lorenzoalfaro.ctrrecomp"
$Ctr = Resolve-Path "..\CTRStaticRecomp"
$ndk = "$Sdk\ndk\$NdkVersion"
$bt = "$Sdk\build-tools\$BuildTools"
$androidJar = "$Sdk\platforms\$Platform\android.jar"
$adb = "$Sdk\platform-tools\adb.exe"
$env:JAVA_HOME = $Jdk
$env:PATH = "$Sdk\cmake\$CMakeVersion\bin;$Jdk\bin;$env:PATH"
# prefer a real Python over the Windows Store "python" alias
foreach ($d in "$env:LOCALAPPDATA\Python\bin", "$env:LOCALAPPDATA\Programs\Python\Python314") {
    if (Test-Path "$d\python.exe") { $env:PATH = "$d;$env:PATH"; break }
}
foreach ($p in $ndk, $bt, $androidJar, "$Ctr\data\SCUS_944.26") {
    if (-not (Test-Path $p)) { throw "missing: $p" }
}
New-Item -ItemType Directory -Force build | Out-Null

# 1. recompile the game code (platform-independent C)
$syms = @()
if (Test-Path "$Ctr\data\syms926.txt") { $syms = @("--syms", "$Ctr\data\syms926.txt") }
python "$Ctr\gen\recomp.py" --data "$Ctr\data" --out build/gen @syms | Out-Null
if ($LASTEXITCODE) { throw "recompiler failed" }

# 2. native libraries, one build per ABI (arm64-v8a: phones; armeabi-v7a: 32-bit devices such
#    as most Android TVs)
$strip = "$ndk\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-strip.exe"
$libs = @()
foreach ($abi in $Abis) {
    $bdir = if ($abi -eq "arm64-v8a") { "build/native" } else { "build/native-$abi" }
    cmake -S . -B $bdir -G Ninja -DCMAKE_BUILD_TYPE=Release `
        "-DCMAKE_TOOLCHAIN_FILE=$ndk\build\cmake\android.toolchain.cmake" `
        "-DANDROID_ABI=$abi" -DANDROID_PLATFORM=android-26 "-DCTR_ROOT=$Ctr" "-DGEN_DIR=$PWD/build/gen" | Out-Null
    if ($LASTEXITCODE) { throw "cmake configure failed ($abi)" }
    cmake --build $bdir -j $env:NUMBER_OF_PROCESSORS
    if ($LASTEXITCODE) { throw "native build failed ($abi)" }
    $libdir = "build/apk/lib/$abi"
    New-Item -ItemType Directory -Force $libdir | Out-Null
    $stripArgs = if ($NoStrip) { @("--strip-debug") } else { @() }
    & $strip @stripArgs -o "$libdir/libSDL2.so" (Get-ChildItem $bdir -Recurse -Filter libSDL2.so | Select-Object -First 1).FullName
    & $strip @stripArgs -o "$libdir/libmain.so" "$bdir/libmain.so"
    $libs += "$libdir/libSDL2.so", "$libdir/libmain.so"
}

# 3. Java: SDL's activity/glue classes + ours
$sdlJava = "build/native/_deps/sdl2-src/android-project/app/src/main/java"
$src = "build/java/src"
if (Test-Path build/java) { [IO.Directory]::Delete("$PWD\build\java", $true) }
New-Item -ItemType Directory -Force $src, build/java/classes | Out-Null
Copy-Item -Recurse "$sdlJava\*" $src
Copy-Item -Recurse "java\*" $src -Force
# the recompiled game recurses deeper than a default Java thread stack allows
$act = "$src\org\libsdl\app\SDLActivity.java"
$code = [IO.File]::ReadAllText($act)
$patched = $code.Replace('new Thread(new SDLMain(), "SDLThread")', 'new Thread(null, new SDLMain(), "SDLThread", 64L * 1024 * 1024)')
if ($patched -eq $code) { throw "SDLActivity thread patch did not apply" }
[IO.File]::WriteAllText($act, $patched)
$javaFiles = Get-ChildItem $src -Recurse -Filter *.java | ForEach-Object { $_.FullName }
javac -nowarn --release 17 -cp $androidJar -d build/java/classes @javaFiles
if ($LASTEXITCODE) { throw "javac failed" }
$classes = Get-ChildItem build/java/classes -Recurse -Filter *.class | ForEach-Object { $_.FullName }
& "$bt\d8.bat" --release --min-api 26 --lib $androidJar --output build/java @classes
if ($LASTEXITCODE) { throw "d8 failed" }

# 4. package, align, sign
# resources: just the Android TV home-screen banner
& "$bt\aapt2.exe" compile --dir res -o build/res.zip
if ($LASTEXITCODE) { throw "aapt2 compile failed" }
& "$bt\aapt2.exe" link -o build/base.apk --manifest AndroidManifest.xml -I $androidJar build/res.zip
if ($LASTEXITCODE) { throw "aapt2 link failed" }
python tools/package_apk.py build/base.apk build/unaligned.apk build/java/classes.dex @libs
if ($LASTEXITCODE) { throw "packaging failed" }
& "$bt\zipalign.exe" -P 16 -f 4 build/unaligned.apk build/aligned.apk
if ($LASTEXITCODE) { throw "zipalign failed" }
$ks = "$env:USERPROFILE\.android\debug.keystore"
if (-not (Test-Path $ks)) {
    keytool -genkeypair -keystore $ks -storepass android -keypass android -alias androiddebugkey `
        -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
}
& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:android --key-pass pass:android --out ctr-recomp.apk build/aligned.apk
if ($LASTEXITCODE) { throw "apksigner failed" }
Write-Host "Built ctr-recomp.apk ($([int]((Get-Item ctr-recomp.apk).Length / 1MB)) MB)"

if ($Install -or $Run) {
    & $adb install -r ctr-recomp.apk
    if ($LASTEXITCODE) { throw "adb install failed" }
}
if ($Run) {
    & $adb shell am start -n "$Package/.CTRActivity"
}
