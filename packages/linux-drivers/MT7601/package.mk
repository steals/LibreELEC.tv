################################################################################
#      This file is part of LibreELEC - https://LibreELEC.tv
#      Copyright (C) 2016 Team LibreELEC
#      Copyright (C) 2018 steals
#
#  LibreELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  LibreELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LibreELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
PKG_NAME="MT7601"
PKG_VERSION="50b6c56"
PKG_ARCH="any"
PKG_LICENSE="GPL"
# realtek: PKG_SITE="http://www.realtek.com.tw/downloads/downloadsView.aspx?Langid=1&PFid=48&Level=5&Conn=4&ProdID=274&DownTypeID=3&GetDown=false&Downloads=true"
PKG_SITE="https://github.com/steals/mt7601.git"
PKG_URL="https://github.com/steals/mt7601/archive/$PKG_VERSION.tar.gz"
PKG_SOURCE_DIR="mt7601-$PKG_VERSION*"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="$LINUX_DEPENDS"
PKG_SECTION="driver"
PKG_SHORTDESC="MT7601U Linux 3.x driver"
PKG_LONGDESC="MT7601U Linux 3.x driver"

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

pre_make_target() {
  unset LDFLAGS
  sed -i '108s|.*LINUX_SRC.*|LINUX_SRC = '$(kernel_path)'|' src/Makefile
  sed -i '109s|.*LINUX_SRC_MODULE.*|LINUX_SRC_MODULE = '$INSTALL'/usr/lib/modules/'$(get_module_dir)'/kernel/drivers/net/wireless/|' src/Makefile
  sed -i '110s|.*CROSS_COMPILE.*|CROSS_COMPILE = '$TOOLCHAIN'/bin/armv7a-libreelec-linux-gnueabi-|' src/Makefile
}

make_target() {
  cd src/
  make V=1 
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/lib/modules/$(get_module_dir)/kernel/drivers/net/wireless/$PKG_NAME
  mkdir -p $INSTALL/usr/lib/firmware/
  cp RT2870STA.dat $INSTALL/usr/lib/firmware/RT2870STA_7601.dat
  cp os/linux/mt7601Usta.ko $INSTALL/usr/lib/modules/$(get_module_dir)/kernel/drivers/net/wireless/$PKG_NAME
}
