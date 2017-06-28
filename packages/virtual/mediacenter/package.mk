################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
#
#  OpenELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  OpenELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="mediacenter"
PKG_VERSION=""
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain $MEDIACENTER"
PKG_SECTION="virtual"
PKG_SHORTDESC="Mediacenter: Metapackage"
PKG_LONGDESC=""

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

_add_binary_addon() {
  [ -f $ROOT/$PACKAGES/mediacenter/kodi-binary-addons/$1/package.mk ] && PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $1" || true
}

if [ "$MEDIACENTER" = "kodi" ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $MEDIACENTER-theme-$SKIN_DEFAULT"

  for i in $SKINS; do
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET $MEDIACENTER-theme-$i"
  done
  
# some python stuff needed for various addons
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET Pillow \
                                          simplejson \
                                          pycryptodome"
# other packages
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET LibreELEC-settings \
                                          xmlstarlet"
  
  if [ "$JOYSTICK_SUPPORT" = "yes" ]; then
    PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET peripheral.joystick"
  fi

  _ADDONS_PVR=yes
#  _ADDONS_ADSP=yes
#  _ADDONS_GAME=no
  _ADDONS_OTHER=yes

  # various PVR clients
  if [ "${_ADDONS_PVR}" = "yes" ]; then
    _add_binary_addon "pvr.hts"
  fi

  if [ "${_ADDONS_ADSP}" = "yes" ]; then
    _add_binary_addon "adsp.basic"
    _add_binary_addon "adsp.freesurround"
    _add_binary_addon "adsp.biquad.filters"
  fi

  if [ "${_ADDONS_GAME}" = "yes" ]; then
    _add_binary_addon "peripheral.steamcontroller"
    _add_binary_addon "game.libretro.2048"
    _add_binary_addon "game.libretro.beetle-bsnes"
    _add_binary_addon "game.libretro.beetle-gba"
    _add_binary_addon "game.libretro.beetle-pce-fast"
    _add_binary_addon "game.libretro.bluemsx"
    _add_binary_addon "game.libretro.bnes"
    _add_binary_addon "game.libretro.bsnes-mercury-accuracy"
    _add_binary_addon "game.libretro.bsnes-mercury-balanced"
    _add_binary_addon "game.libretro.bsnes-mercury-performance"
    _add_binary_addon "game.libretro.dosbox"
    _add_binary_addon "game.libretro.fceumm"
    _add_binary_addon "game.libretro.gambatte"
    _add_binary_addon "game.libretro.genplus"
    _add_binary_addon "game.libretro.mame"
    _add_binary_addon "game.libretro.meteor"
    _add_binary_addon "game.libretro.mgba"
    _add_binary_addon "game.libretro.mupen64plus"
    _add_binary_addon "game.libretro.nestopia"
    _add_binary_addon "game.libretro.pcsx-rearmed"
    _add_binary_addon "game.libretro.quicknes"
    _add_binary_addon "game.libretro.snes9x-next"
    _add_binary_addon "game.libretro.snes9x"
    _add_binary_addon "game.libretro.stella"
    _add_binary_addon "game.libretro.vba-next"
    _add_binary_addon "game.libretro.vbam"
    _add_binary_addon "game.libretro.yabause"
    _add_binary_addon "game.libretro"
  fi

  if [ "${_ADDONS_OTHER}" = "yes" ]; then
    _add_binary_addon "inputstream.adaptive"
    _add_binary_addon "inputstream.smoothstream"
#    _add_binary_addon "inputstream.rtmp"
    _add_binary_addon "imagedecoder.raw"
    _add_binary_addon "vfs.rar"
  fi
fi
