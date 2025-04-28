
{ pkgs ? import <nixpkgs> {} }:
with pkgs;
mkShell {

  nativeBuildInputs = [
    clang
    cmake
    ninja
    pkg-config

    gtk3  # Curiously `nix-env -i` can't handle this one adequately.
          # But `nix-shell` on this shell.nix does fine.
    pcre
    libepoxy

    # This group all seem not strictly necessary -- commands like
    # `flutter run -d linux` seem to *work* fine without them, but
    # the build does print messages about missing packages, like:
    #   Package mount was not found in the pkg-config search path.
    #   Perhaps you should add the directory containing `mount.pc'
    #   to the PKG_CONFIG_PATH environment variable
    # To add to this list on NixOS upgrades, the Nix package
    # `nix-index` is handy: then `nix-locate mount.pc`.
    libuuid  # for mount.pc
    xorg.libXdmcp.dev
    python310Packages.libselinux.dev # for libselinux.pc
    libsepol.dev
    libthai.dev
    libdatrie.dev
    libxkbcommon.dev
    dbus.dev
    at-spi2-core.dev
    xorg.libXtst.out
    pcre2.dev

    jdk17
    android-studio
    android-tools

    nodejs
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [
    fontconfig.lib
    sqlite.out
  ];
}
