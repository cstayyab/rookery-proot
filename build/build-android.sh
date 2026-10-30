#!/usr/bin/env bash
# Cross-compiles PRoot for Android as shipped in the Rookery app.
#
# Usage: build/build-android.sh <abi>...    (default: all ABIs below)
# Needs: ANDROID_NDK_HOME (NDK r27c), make, python3, binutils.
# Output: out/jniLibs/<abi>/libproot.so, libproot-loader.so
#         and, on 64-bit ABIs, libproot-loader32.so.
#
# The loader is unbundled: Android 10+ forbids executing files from an
# app's writable storage, so the loader ships in the APK's native
# library directory and the app points PRoot at it with PROOT_LOADER
# and PROOT_LOADER_32.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
API=26
TALLOC=talloc-2.5.0
ALL_ABIS="arm64-v8a armeabi-v7a x86_64"
APP_TMP=/data/data/com.cstayyab.rookery/cache/

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to an NDK r27c install}"
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"

triple_for() {
	case "$1" in
		arm64-v8a)   echo aarch64-linux-android ;;
		armeabi-v7a) echo armv7a-linux-androideabi ;;
		x86_64)      echo x86_64-linux-android ;;
		*) echo "unknown ABI: $1" >&2; exit 1 ;;
	esac
}

build_abi() {
	local abi=$1 triple work prefix dest
	triple=$(triple_for "$abi")
	work="$ROOT/out/build/$abi"
	prefix="$work/prefix"
	dest="$ROOT/out/jniLibs/$abi"
	rm -rf "$work" "$dest"
	mkdir -p "$prefix/lib" "$prefix/include/sys" "$dest"

	export CC="$TOOLCHAIN/bin/$triple$API-clang"
	export AR="$TOOLCHAIN/bin/llvm-ar"
	export STRIP="$TOOLCHAIN/bin/llvm-strip"
	export OBJCOPY="$TOOLCHAIN/bin/llvm-objcopy"
	export OBJDUMP="$TOOLCHAIN/bin/llvm-objdump"

	# talloc (LGPL-3.0), static. Same cross answers as Termux's recipe.
	cp -r "$ROOT/third_party/$TALLOC" "$work/talloc"
	(
		cd "$work/talloc"
		cp "$ROOT/build/talloc-cross-answers.txt" cross-answers.txt
		./configure --prefix="$prefix" --disable-rpath --disable-python \
			--cross-compile --cross-answers=cross-answers.txt
		make -j"$(nproc)"
		cd bin/default
		"$AR" rcs "$prefix/lib/libtalloc.a" talloc*.o
		cp "$work/talloc/talloc.h" "$prefix/include/"
	)

	# libandroid-shmem (BSD-3-Clause), static. Backs SysV shared memory,
	# which Android lacks, for programs running under PRoot (X11 MIT-SHM).
	# Termux's libc defines _PATH_TMP, the NDK's doesn't: point it at the
	# app's cache, where it keeps the symlinks that share segment keys.
	cp -r "$ROOT/third_party/libandroid-shmem" "$work/shmem"
	CFLAGS="-D_PATH_TMP=\\\"$APP_TMP\\\"" make -C "$work/shmem" libandroid-shmem.a
	cp "$work/shmem/libandroid-shmem.a" "$prefix/lib/"
	cp "$work/shmem/shm.h" "$prefix/include/sys/shm.h"

	# PRoot (GPL-2.0-or-later), built in a copy of src/ per ABI. Flags go
	# through the environment: on the command line they would replace,
	# not extend, the GNUmakefile's own -ltalloc and -landroid-shmem.
	cp -r "$ROOT/src" "$work/proot"
	CPPFLAGS="-I$prefix/include -DARG_MAX=131072" \
	LDFLAGS="-L$prefix/lib -landroid -llog -Wl,-z,max-page-size=16384" \
	make -C "$work/proot" -j"$(nproc)" \
		PROOT_WITH_LIBANDROID_SHMEM=true \
		PROOT_UNBUNDLE_LOADER=/rookery-set-PROOT_LOADER

	"$STRIP" -o "$dest/libproot.so" "$work/proot/proot"
	"$STRIP" -o "$dest/libproot-loader.so" "$work/proot/loader/loader"
	if [ -e "$work/proot/loader/loader-m32" ]; then
		"$STRIP" -o "$dest/libproot-loader32.so" "$work/proot/loader/loader-m32"
	fi
	ls -l "$dest"
}

for abi in ${@:-$ALL_ABIS}; do
	build_abi "$abi"
done
