#!/bin/sh

FPCARCH=x86_64-linux
DEST=../../../static/$FPCARCH 
GCC=gcc

echo
echo ---------------------------------------------------
echo Compiling for FPC on $FPCARCH using $GCC

rm $DEST/libdeflatepas.a
rm *.o

$GCC -static -fno-pic -fno-stack-protector -O2 -m64 -fomit-frame-pointer -fno-exceptions -fno-asynchronous-unwind-tables  -fno-unwind-tables -std=c99 -I. -Wall -Wundef -nostdlib -fvisibility=hidden -D_ANSI_SOURCE  -c  lib/deflate_decompress.c lib/utils.c lib/x86/cpu_features.c lib/deflate_compress.c lib/adler32.c lib/crc32.c lib/zlib_decompress.c  lib/zlib_compress.c
# we removed -ffreestanding for gcc-10 which drops the performance by half 

strip -d -x *.o

ar rcs libdeflatepas.a cpu_features.o utils.o adler32.o crc32.o  deflate_compress.o deflate_decompress.o zlib_compress.o zlib_decompress.o

mv libdeflatepas.a $DEST
