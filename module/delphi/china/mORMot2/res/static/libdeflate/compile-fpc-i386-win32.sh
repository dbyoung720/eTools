#!/bin/sh

FPCARCH=i386-win32
DEST=../../../static/$FPCARCH
GCC=i686-w64-mingw32-gcc

echo
echo ---------------------------------------------------
echo Compiling for FPC on $FPCARCH using $GCC

rm $DEST/libdeflatepas.a
rm *.o

$GCC -static -fno-pic -fno-stack-protector -O2 -m32 -fomit-frame-pointer -fno-exceptions -fno-asynchronous-unwind-tables  -fno-unwind-tables -std=c99 -I. -Wall -Wundef -nostdlib -fvisibility=hidden -DWIN32 -D_ANSI_SOURCE  -c  lib/deflate_decompress.c lib/utils.c lib/x86/cpu_features.c lib/deflate_compress.c lib/adler32.c lib/crc32.c lib/zlib_decompress.c  lib/zlib_compress.c

strip -d -x *.o

ar rcs libdeflatepas.a cpu_features.o utils.o adler32.o crc32.o  deflate_compress.o deflate_decompress.o zlib_compress.o zlib_decompress.o

mv libdeflatepas.a $DEST