"""Add classes.dex and native libraries to the APK produced by `aapt2 link`.

Usage: python tools/package_apk.py base.apk out.apk classes.dex lib/arm64-v8a/libSDL2.so ...
Each native library is stored uncompressed under lib/<abi>/, so zipalign -P 16 can
page-align it.
"""
import shutil
import sys
import zipfile


def main():
    base, out, dex, *libs = sys.argv[1:]
    shutil.copyfile(base, out)
    with zipfile.ZipFile(out, "a") as z:
        z.write(dex, "classes.dex", compress_type=zipfile.ZIP_DEFLATED)
        for lib in libs:
            parts = lib.replace("\\", "/").split("/")
            name = "/".join(parts[parts.index("lib"):])  # lib/<abi>/libX.so
            z.write(lib, name, compress_type=zipfile.ZIP_STORED)


if __name__ == "__main__":
    main()
