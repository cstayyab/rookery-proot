# rookery-proot

The source of the PRoot binaries shipped inside the Rookery Android app, published to meet
PRoot's GPL-2.0 licence. Rookery itself is closed source. It runs PRoot only as a separate
program, through `exec`, and never links it into the app.

## What's here

| Path | What it is | Licence |
|---|---|---|
| `src/`, `doc/`, `tests/` | PRoot from [termux/proot](https://github.com/termux/proot), tag `v5.1.107.101`, with its full history | GPL-2.0-or-later (`COPYING`) |
| `third_party/talloc-2.5.0/` | talloc, linked statically into PRoot | LGPL-3.0-or-later |
| `third_party/libandroid-shmem/` | SysV shared memory on Android, linked statically into PRoot | BSD-3-Clause |
| `build/build-android.sh` | The script that builds the shipped binaries | GPL-2.0-or-later |

The original PRoot README is at [README.proot.md](README.proot.md). Pinned versions and
checksums of the third-party code are in [third_party/README.md](third_party/README.md).

## Build

On Linux x86_64, with [Android NDK r27c](https://developer.android.com/ndk/downloads):

```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r27c
build/build-android.sh            # or: build/build-android.sh arm64-v8a
```

The output goes to `out/jniLibs/<abi>/`:

- `libproot.so`: the `proot` executable, named so Android installs it in the app's native library folder
- `libproot-loader.so`: the loader, kept out of `proot` because Android 10+ won't execute files from app storage
- `libproot-loader32.so`: the loader for 32-bit programs (64-bit ABIs only)

The app sets `PROOT_LOADER` and `PROOT_LOADER_32` to the loaders' paths.

## Releases

Each tag `v<proot version>-rookery.<n>` matches a Rookery app release. CI builds the
binaries from that tag and attaches them to a
[GitHub release](https://github.com/cstayyab/rookery-proot/releases) together with a source
archive of the tag. Each app version's Open source screen links to its tag.

## Written offer

For at least three years after each Rookery release, we'll provide the complete
corresponding source of the PRoot binaries in that release to anyone who asks, at no charge
beyond the cost of providing it. To ask, open an issue in this repository.
