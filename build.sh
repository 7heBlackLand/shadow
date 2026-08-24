#!/bin/bash
#
# Shadow.iso build script (forked from the official Kali live-build build.sh)
#
# Builds a lightweight, customized Kali Linux Live ISO with the Shadow desktop.
#
# Usage:
#   ./build.sh minimal          # minimal profile  -> images/shadow-minimal.iso
#   ./build.sh extended          # extended profile -> images/shadow-extended.iso
#   PROFILE=minimal ./build.sh   # profile via env var (default: minimal)
#
# Extra options (passed through to live-build):
#   --arch <arch>  --distribution <dist>  --verbose  --debug  --no-clean ...

set -e
set -o pipefail

KALI_DIST="kali-rolling"
KALI_VERSION=""
KALI_VARIANT=""
TARGET_DIR="$(dirname $0)/images"
TARGET_SUBDIR=""
SUDO="sudo"
VERBOSE=""
DEBUG=""
HOST_ARCH=$(dpkg --print-architecture)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Resolve profile (first positional arg, or PROFILE env). Default: minimal
PROFILE="${PROFILE:-minimal}"
case "$1" in
  minimal|extended)
    PROFILE="$1"
    shift
    ;;
esac
case "$PROFILE" in
  minimal|extended) KALI_VARIANT="$PROFILE" ;;
  *)
    echo "ERROR: Unknown profile '$PROFILE' (use 'minimal' or 'extended')" >&2
    exit 1
    ;;
esac

image_name() {
  case "$KALI_ARCH" in
    i386|amd64|arm64)
      echo "live-image-$KALI_ARCH.hybrid.iso"
    ;;
    armhf)
      echo "live-image-$KALI_ARCH.img"
    ;;
  esac
}

# Shadow naming: shadow-<profile>.<ext>
target_image_name() {
  local arch=$1
  IMAGE_NAME="$(image_name $arch)"
  IMAGE_EXT="${IMAGE_NAME##*.}"
  if [ "$IMAGE_EXT" = "$IMAGE_NAME" ]; then
    IMAGE_EXT="img"
  fi
  echo "shadow-$PROFILE.$IMAGE_EXT"
}

target_build_log() {
  TARGET_IMAGE_NAME=$(target_image_name $1)
  echo ${TARGET_IMAGE_NAME%.*}.log
}

default_version() {
  case "$1" in
    kali-*) echo "${1#kali-}" ;;
    *) echo "$1" ;;
  esac
}

failure() {
  echo "Build of $KALI_DIST/$PROFILE/$KALI_ARCH live image failed (see build.log for details)" >&2
  echo "Log: $BUILD_LOG" >&2
  exit 2
}

run_and_log() {
  if [ -n "$VERBOSE" ] || [ -n "$DEBUG" ]; then
    printf "RUNNING:" >&2
    for _ in "$@"; do
      case "$_" in
        *" "*) printf " '%s'" "$_" ;;
        *) printf " %s" "$_" ;;
      esac
    done >&2
    printf "\n" >&2
    "$@" 2>&1 | tee -a "$BUILD_LOG"
  else
    "$@" >>"$BUILD_LOG" 2>&1
  fi
  return $?
}

debug() {
  if [ -n "$DEBUG" ]; then
    echo "DEBUG: $*" >&2
  fi
}

clean() {
  debug "Cleaning"
  run_and_log $SUDO lb clean --purge
}

print_help() {
  echo "Usage: $0 [minimal|extended] [<option>...]"
  echo
  echo "Profiles:"
  echo "  minimal   Lightweight Shadow desktop + base business/security tools"
  echo "  extended  minimal + additional selected security tools"
  echo
  for x in $(echo "${BUILD_OPTS_LONG}" | sed 's_,_ _g'); do
    x=$(echo $x | sed 's/:$/ <arg>/')
    echo "  --${x}"
  done
  echo
  echo "More information: https://www.kali.org/docs/development/live-build-a-custom-kali-iso/"
  exit 0
}

require_package() {
  local pkg=$1
  local required_version=$2
  local pkg_version=
  pkg_version=$(dpkg-query -f '${Version}' -W $pkg 2>/dev/null || true)
  if [ -z "$pkg_version" ]; then
    echo "ERROR: You need $pkg, but it is not installed" >&2
    exit 1
  fi
  if dpkg --compare-versions "$pkg_version" lt "$required_version"; then
    echo "ERROR: You need $pkg (>= $required_version), you have $pkg_version" >&2
    exit 1
  fi
  debug "$pkg version: $pkg_version"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cd $(dirname $0)/

source .getopt.sh

temp=$(getopt -o "$BUILD_OPTS_SHORT" -l "$BUILD_OPTS_LONG" -- "$@")
eval set -- "$temp"
while true; do
  case "$1" in
    -d|--distribution) KALI_DIST="$2"; shift 2; ;;
    -p|--proposed-updates) OPT_pu="1"; shift 1; ;;
    -a|--arch) KALI_ARCH="$2"; shift 2; ;;
    -v|--verbose) VERBOSE="1"; shift 1; ;;
    -D|--debug) DEBUG="1"; shift 1; ;;
    -h|--help) print_help; ;;
    --variant) KALI_VARIANT="$2"; shift 2; ;;
    --version) KALI_VERSION="$2"; shift 2; ;;
    --subdir) TARGET_SUBDIR="$2"; shift 2; ;;
    --get-image-path) ACTION="get-image-path"; shift 1; ;;
    --clean) ACTION="clean"; shift 1; ;;
    --no-clean) NO_CLEAN="1"; shift 1 ;;
    --) shift; break; ;;
    *) echo "ERROR: Invalid command-line option: $1" >&2; exit 1; ;;
  esac
done

# --variant overrides profile if explicitly given
case "$KALI_VARIANT" in
  minimal|extended) PROFILE="$KALI_VARIANT" ;;
  "") KALI_VARIANT="$PROFILE" ;;
esac

BUILD_LOG="$(pwd)/build.log"
debug "BUILD_LOG: $BUILD_LOG"
: > "$BUILD_LOG"

KALI_ARCH=${KALI_ARCH:-$HOST_ARCH}
if [ "$KALI_ARCH" = "x64" ]; then KALI_ARCH="amd64"
elif [ "$KALI_ARCH" = "x86" ]; then KALI_ARCH="i386"; fi
debug "KALI_ARCH: $KALI_ARCH"

if [ -z "$KALI_VERSION" ]; then
  KALI_VERSION="$(default_version $KALI_DIST)"
fi
debug "KALI_VERSION: $KALI_VERSION"

debug "HOST_ARCH: $HOST_ARCH"
if [ "$HOST_ARCH" != "$KALI_ARCH" ]; then
  case "$HOST_ARCH/$KALI_ARCH" in
    amd64/i386|i386/amd64) ;;
    *) echo "Can't build $KALI_ARCH image on $HOST_ARCH system" >&2; exit 1 ;;
  esac
fi

KALI_CONFIG_OPTS="--distribution $KALI_DIST -- --variant $KALI_VARIANT"
if [ -n "$OPT_pu" ]; then
  KALI_CONFIG_OPTS="$KALI_CONFIG_OPTS --proposed-updates"
  KALI_DIST="$KALI_DIST+pu"
fi
debug "KALI_CONFIG_OPTS: $KALI_CONFIG_OPTS"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if grep -q -e "^ID=debian" -e "^ID_LIKE=debian" /usr/lib/os-release; then
  debug "OS: $( . /usr/lib/os-release && echo $NAME $VERSION )"
elif [ -e /etc/debian_version ]; then
  debug "OS: $( cat /etc/debian_version )"
else
  echo "ERROR: Non Debian-based OS" >&2
fi

if [ ! -d "$(dirname $0)/kali-config/variant-$KALI_VARIANT" ]; then
  echo "ERROR: Unknown variant of Kali live configuration: $KALI_VARIANT" >&2
  exit 1
fi
require_package live-build "1:20250814+kali2"

if [ "$(whoami)" != "root" ]; then
  if ! which $SUDO >/dev/null; then
    echo "ERROR: $0 is not run as root and $SUDO is not available" >&2
    exit 1
  fi
else
  SUDO=""
fi
debug "SUDO: $SUDO"

IMAGE_NAME="$(image_name $KALI_ARCH)"
IMAGE_EXT="${IMAGE_NAME##*.}"
if [ "$IMAGE_EXT" = "$IMAGE_NAME" ]; then
  IMAGE_EXT="img"
fi
debug "IMAGE_NAME: $IMAGE_NAME"
debug "IMAGE_EXT: $IMAGE_EXT"

debug "ACTION: $ACTION"
if [ "$ACTION" = "get-image-path" ]; then
  echo $(target_image_name $KALI_ARCH)
  exit 0
fi

if [ "$NO_CLEAN" = "" ]; then
  clean
fi
if [ "$ACTION" = "clean" ]; then
  exit 0
fi

mkdir -pv $TARGET_DIR/$TARGET_SUBDIR
[ $? -eq 0 ] || failure

set +e

debug "Stage 1/2 - Config"
run_and_log lb config -a $KALI_ARCH $KALI_CONFIG_OPTS "$@"
[ $? -eq 0 ] || failure

debug "Stage 2/2 - Build"
run_and_log $SUDO lb build
if [ $? -ne 0 ] || [ ! -e $IMAGE_NAME ]; then
  failure
fi

set -e

debug "Moving files"
run_and_log mv -f $IMAGE_NAME $TARGET_DIR/$(target_image_name $KALI_ARCH)
run_and_log mv -f "$BUILD_LOG" $TARGET_DIR/$(target_build_log $KALI_ARCH)

# Generic alias shadow.iso -> shadow-<profile>.iso
( cd $TARGET_DIR/$TARGET_SUBDIR && cp -f "shadow-$PROFILE.${IMAGE_EXT}" "shadow.${IMAGE_EXT}" ) 2>/dev/null || true

# SHA256 + build info
FINAL_ISO="$TARGET_DIR/$TARGET_SUBDIR/shadow-$PROFILE.${IMAGE_EXT}"
SHA="${FINAL_ISO}.sha256"
BUILDINFO="${FINAL_ISO%.*}.buildinfo.txt"
sha256sum "$(basename "$FINAL_ISO")" > "$SHA" 2>/dev/null || \
  ( cd "$TARGET_DIR/$TARGET_SUBDIR" && sha256sum "shadow-$PROFILE.${IMAGE_EXT}" > "shadow-$PROFILE.${IMAGE_EXT}.sha256" )
cat > "$BUILDINFO" <<INFO
Shadow.iso build information
===========================
Profile     : $PROFILE
Variant     : $KALI_VARIANT
Arch        : $KALI_ARCH
Distribution : $KALI_DIST
Version     : $KALI_VERSION
Date        : $(date -u)
Image       : $(basename "$FINAL_ISO")
INFO

echo -e "\n***\nGENERATED SHADOW IMAGE: $(readlink -f "$FINAL_ISO")\n***"
echo "SHA256 : $SHA"
echo "INFO   : $BUILDINFO"
