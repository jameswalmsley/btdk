TARGET=arm-eabi-bt
PREFIX=/opt/btdk
#HOST=i686-w64-mingw32
NEWLIB_OPTIONS=--enable-target-optspace --enable-newlib-hw-fp

export PATH := $(PATH):${PREFIX}/bin/

# Simple dependency tree
all: toolchain

toolchain: binutils gcc_pre gcc newlib libmpfr libgmp libmpc
gcc_pre: binutils libmpfr libgmp libmpc
libmpc: libgmp libmpfr
libmpfr: libgmp
newlib: gcc_pre
gcc: newlib

include packages.mk

PKGVERSION="BitThunder BTDK ($(shell git describe))"

ROOT=$(shell pwd)

binutils:
	@rm -rf build-binutils
	@mkdir build-binutils
	@cd build-binutils && ../sources/binutils/configure --host=${HOST} --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-target-optspace --with-float=soft --disable-werror --with-pkgversion=${PKGVERSION}
	@cd build-binutils && $(MAKE)
	@cd build-binutils && sudo make install
	@touch binutils

libmpfr:
	@rm -rf build-libmpfr
	@mkdir build-libmpfr
	@cd build-libmpfr && ../sources/libmpfr/configure --prefix=$(shell pwd)/libmpfr --with-gmp=$(ROOT)/libgmp --disable-shared --enable-static
	@cd build-libmpfr && $(MAKE)
	@cd build-libmpfr && $(MAKE) check
	@cd build-libmpfr && $(MAKE) install

libgmp:
	@rm -rf build-libgmp
	@mkdir build-libgmp
	@cd build-libgmp && ../sources/libgmp/configure --prefix=$(shell pwd)/libgmp --disable-shared --enable-static
	@cd build-libgmp && $(MAKE)
	#@cd build-libgmp && $(MAKE) check
	@cd build-libgmp && $(MAKE) install

libmpc:
	@rm -rf build-libmpc
	@mkdir build-libmpc
	@cd build-libmpc && ../sources/libmpc/configure --prefix=$(shell pwd)/libmpc --with-gmp=$(ROOT)/libgmp --with-mpfr=$(ROOT)/libmpfr --disable-shared --enable-static 
	@cd build-libmpc && $(MAKE)
	@cd build-libmpc && $(MAKE) install

gcc_pre:
	@rm -rf build-gcc
	@mkdir build-gcc
	@cd build-gcc && ../sources/gcc/configure --host=${HOST} --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-languages="c" --with-newlib --without-headers --disable-shared --disable-libssp --with-gnu-as --with-gnu-ld --disable-nls --with-pkgversion=${PKGVERSION} --with-gmp=$(ROOT)/libgmp --with-mpfr=$(ROOT)/libmpfr --with-mpc=$(ROOT)/libmpc
	@cd build-gcc && $(MAKE) all-gcc
	@cd build-gcc && sudo $(MAKE) install-gcc
	@cd build-gcc && $(MAKE) all-target-libgcc
	@cd build-gcc && sudo $(MAKE) install-target-libgcc
	@touch gcc_pre

newlib:
	@rm -rf build-newlib
	@mkdir build-newlib
	@cd build-newlib && ../sources/newlib/configure --host=${HOST} --target=${TARGET} --prefix=${PREFIX} ${NEWLIB_OPTIONS} --enable-interwork --enable-multilib --with-gnu-as --with-gnu-ls --disable-libgloss --disable-libssp --with-pkgversion=${PKGVERSION}
	@cd build-newlib && sed -i "s|RANLIB_FOR_TARGET=${TARGET}-ranlib|RANLIB_FOR_TARGET=${PREFIX}/bin/${TARGET}-ranlib|g" Makefile
	@cd build-newlib && $(MAKE) all
	@cd build-newlib && sudo $(MAKE) install
	@touch newlib

gcc:
	@cd build-gcc && ../sources/gcc/configure --host=${HOST} --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-languages="c" --with-newlib --disable-shared --disable-libssp --with-gnu-as --with-gnu-ld --disable-nls --with-pkgversion=${PKGVERSION} --with-gmp=$(ROOT)/libgmp --with-mpfr=$(ROOT)/libmpfr --with-mpc=$(ROOT)/libmpc
	@cd build-gcc && $(MAKE) all
	@cd build-gcc && sudo $(MAKE) install
	@touch gcc

libc.update:
	@cd build-newlib && $(MAKE) all
	@cd build-newlib && sudo $(MAKE) install
	@sudo bash install-libc.sh $(PREFIX) $(TARGET)

libc.install: newlib
	@sudo bash install-libc.sh $(PREFIX) $(TARGET)

toolchain:
	@echo "BTDK sucessfully compiled"

ubuntu.prerequisites:
	@sudo apt-get install ${PACKAGES}

clean:
	@-rm binutils gcc_pre newlib gcc
	@-rm -rf libgmp libmpfr libmpc
	@-rm -rf build-*
