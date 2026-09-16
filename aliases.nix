# Aliases for system dependencies referenced by hackage-packages.nix.
#
# The generated hackage-packages.nix uses `inherit (pkgs) name;` for C/system
# library dependencies. Many of these names don't exist in corepkgs because
# they are either under a different attribute path (e.g. xorg.*) or simply
# not yet packaged. This overlay provides the mapping.
final: prev: {
  # ---- Packages not available in corepkgs -------------------------------------
  # Haskell packages depending on these will fail to build until the
  # corresponding system library is added to corepkgs.

  # Audio / multimedia
  alure = null;
  audiofile = null;
  codec2 = null;
  flac = null;
  fluidsynth = null;
  freealut = null;
  mpg123 = null;
  openal = null;
  opusfile = null;
  pocketsphinx = null;
  portaudio = null;
  rubberband = null;
  SDL = null;
  SDL2 = null;
  SDL2_gfx = null;
  SDL2_image = null;
  SDL2_mixer = null;
  SDL2_ttf = null;
  SDL_gfx = null;
  SDL_image = null;
  SDL_mixer = null;
  SDL_ttf = null;
  smpeg = null;
  sox = null;

  # Graphics / rendering
  assimp = null;
  babl = null;
  bullet = null;
  clutter = null;
  cogl = null;
  directfb = null;
  exif = null;
  freenect = null;
  ftgl = null;
  gegl = null;
  glew = null;
  graphene = null;

  # GTK / GNOME ecosystem
  gtk2 = null;
  gtk4-layer-shell = null;
  gtk-layer-shell = null;
  gtk-mac-integration-gtk2 = null;
  gtk-mac-integration-gtk3 = null;
  gtkimageview = null;
  gtksheet = null;
  gtksourceview = null;
  gtksourceview3 = null;
  gtksourceview5 = null;
  libadwaita = null;
  libdazzle = null;
  libhandy = null;
  libwnck = null;
  vte = null;
  webkitgtk_6_0 = null;

  # D-Bus / desktop integration
  ibus = null;
  libaosd = null;
  libappindicator-gtk2 = null;
  libappindicator-gtk3 = null;
  libayatana-appindicator = null;
  libdbusmenu = null;
  libdbusmenu-gtk3 = null;
  libgnome-keyring = null;
  libnotify = null;
  libpulseaudio = null;

  # Math / science / numerical
  arpack = null;
  casadi = null;
  cfitsio = null;
  clp = null;
  cudd = null;
  flint = null;
  fplll = null;
  geos = null;
  glog = null;
  glpk = null;
  gomp = null;
  gsl = null;
  h3 = null;
  hdf5 = null;
  highs = null;
  ipopt = null;
  nlopt = null;
  picosat = null;
  primecount = null;
  primesieve = null;
  proj = null;
  qhull = null;
  quadprogpp = null;

  # Database / storage
  dbxml = null;
  duckdb = null;
  kyotocabinet = null;
  leveldb = null;
  libmysqlclient = null;
  libpq = null;
  lmdb = null;
  rdkafka = null;
  redland = null;
  tokyocabinet = null;
  tokyotyrant = null;
  zookeeper_mt = null;

  # Networking
  enet = null;
  nanomsg = null;
  net-snmp = null;

  # System / OS
  augeas = null;
  cwiid = null;
  fcgi = null;
  lxc = null;
  ostree = null;
  papi = null;
  pipewire = null;
  sane-backends = null;
  wirelesstools = null;
  zfs = null;

  # Crypto / security / solvers
  boolector = null;
  keystone = null;
  secp256k1 = null;
  yices = null;
  z3 = null;

  # Text / search / NLP
  aspell = null;
  cmph = null;
  enchant = null;
  foma = null;
  groonga = null;
  hunspell = null;
  mecab = null;
  notmuch = null;
  tre = null;

  # General C/C++ libraries
  clingo = null;
  cplex = null;
  double-conversion = null;
  fltk_1_4 = null;
  jasper = null;
  keybinder = null;
  libbladeRF = null;
  libconfig = null;
  libff = null;
  libftdi = null;
  libjack2 = null;
  libnfc = null;
  libossp_uuid = null;
  libpostal = null;
  librsvg = null;
  libsass = null;
  libsndfile = null;
  libstatgrab = null;
  libtelnet = null;
  libtensorflow = null;
  libucl = null;
  libversion = null;
  llama-cpp = null;
  mtr = null;
  ode = null;
  opencc = null;
  openmpi = null;
  poppler_gi = null;
  rure = null;
  shaderc = null;
  symengine = null;
  taglib = null;
  talloc = null;
  tdlib = null;

  # Machine learning / AI
  mxnet = null;
  xgboost = null;

  # SDR / radio
  hamlib = null;
  rtl-sdr = null;
  uhd = null;

  # Misc
  vrpn = null;
  kics = null;
  mono = null;
  netcdf = null;
  opencascade-occt = null;
  pgf = null;
  st = null;
  tango = null;
  trexio = null;
  wlc = null;
  wxGTK = null;
  xercesc = null;
  xosd = null;
  xqilla = null;
  zbar = null;
}
