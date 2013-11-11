TARGET=arm-eabi-bt
PREFIX=/opt/btdk

# Simple dependency tree
all: toolchain

toolchain: binutils gcc_pre gcc newlib
gcc_pre: binutils
newlib: gcc_pre
gcc: newlib

binutils:
	@rm -rf build-binutils
	@mkdir build-binutils
	@cd build-binutils && ../sources/binutils/configure --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-target-optspace --with-float=soft --disable-werror
	@cd build-binutils && $(MAKE)
	@cd build-binutils && sudo make install
	@touch binutils

gcc_pre:
	@rm -rf build-gcc
	@mkdir build-gcc
	@cd build-gcc && ../sources/gcc/configure --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-languages="c" --with-newlib --without-headers --disable-shared --with-gnu-as --with-gnu-ld --disable-nls
	@cd build-gcc && $(MAKE) all-gcc
	@cd build-gcc && sudo $(MAKE) install-gcc
	@cd build-gcc && $(MAKE) all-target-libgcc
	@cd build-gcc && sudo $(MAKE) install-target-libgcc
	@touch gcc_pre

newlib:
	@rm -rf build-newlib
	@mkdir build-newlib
	@cd build-newlib && ../sources/newlib/configure --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --with-gnu-as --with-gnu-ls --disable-libgloss
	@cd build-newlib && sed -i "s|RANLIB_FOR_TARGET=${TARGET}-ranlib|RANLIB_FOR_TARGET=${PREFIX}/bin/${TARGET}-ranlib|g" Makefile
	@cd build-newlib && $(MAKE) all
	@cd build-newlib && sudo $(MAKE) install
	@touch newlib

gcc:
	@cd build-gcc && $(MAKE)
	@cd build-gcc && sudo $(MAKE) install

libc.update:
	@rm newlib
	@rm gcc
	@$(MAKE) toolchain

toolchain:
	@echo "BTDK sucessfully compiled"
