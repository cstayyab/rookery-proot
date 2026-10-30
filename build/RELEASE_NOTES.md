PRoot binaries shipped in the Rookery Android app, and the complete source they were built from.

- `rookery-proot-jniLibs.tar.gz`: `libproot.so`, `libproot-loader.so` and, on 64-bit ABIs, `libproot-loader32.so` for arm64-v8a, armeabi-v7a and x86_64.
- `rookery-proot-source.tar.gz`: the full source of this tag, including talloc and libandroid-shmem and the build script.
- `SHA256SUMS`: checksums of both.

Rebuild with `build/build-android.sh` and Android NDK r27c. See README.md.
