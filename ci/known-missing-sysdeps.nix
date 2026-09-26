# System dependencies referenced by hackage-packages.nix via
# `inherit (pkgs) name` that do not exist in corepkgs.
#
# These are packages from the broader ecosystem not yet ported to
# corepkgs.  The haskell packages that depend on them will fail to
# build, but that is expected — they are typically marked
# `broken = true` or `hydraPlatforms = lib.platforms.none`.
#
# When a name is added to corepkgs, remove it from this list.
# When a name is *renamed* in corepkgs, do NOT add it here — instead
# fix the reference in hackage-packages.nix.
[
  "adns"
  "czmq"
  "double-conversion"
  "emacs"
  "fltk"
  "gdal"
  "gsasl"
  "gtk-layer-shell"
  "gtk-mac-integration-gtk2"
  "gtk-mac-integration-gtk3"
  "gtk4-layer-shell"
  "imlib2"
  "libappindicator-gtk2"
  "libappindicator-gtk3"
  "libayatana-appindicator"
  "libgit2-glib"
  "libgnome-keyring"
  "lksctp-tools"
  "llama-cpp"
  "mosquitto"
  "net-snmp"
  "opencascade-occt"
  "opencv"
  "rtl-sdr"
  "vips"
]
