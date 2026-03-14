# DeskLink

Desktop-only remote access client fork for Windows, macOS, and Linux.

## Scope

- Desktop targets only
- Flutter UI plus legacy Sciter support
- Mobile packaging removed from this fork

## Build

### Requirements

- Rust toolchain
- C/C++ build environment
- `vcpkg` with `VCPKG_ROOT` configured
- Sciter dynamic library if you use the legacy desktop UI

### Quick start

```sh
cargo run
```

### Common commands

```sh
cargo test
python3 build.py --flutter
python3 build.py --flutter --release
```

## Structure

- `src/`: core Rust application code
- `flutter/`: desktop UI code
- `libs/`: shared libraries and platform integrations
- `.github/workflows/`: CI definitions for this fork

## Notes

- This repository is intended for desktop development only.
- Automated workflows are limited in this fork and can be run manually when needed.
