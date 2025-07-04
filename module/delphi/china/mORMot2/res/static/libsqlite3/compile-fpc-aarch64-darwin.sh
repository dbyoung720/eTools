#!/bin/sh

ARCH=aarch64-darwin

CLANG=/home/ab/fpcup/cross/bin/all-apple/bin/aarch64-apple-darwin19-clang
DST=../../static/$ARCH/sqlite3.o
DST2=../../../lib2/static/$ARCH/sqlite3.o

rm $DST
rm $DST2
rm sqlite3-$ARCH.o

echo
echo ---------------------------------------------------
echo Compiling for FPC on $ARCH using $CLANG

$CLANG -static -O2 -DNDEBUG -DNO_TCL -D_CRT_SECURE_NO_DEPRECATE -c sqlite3mc.c -o sqlite3-$ARCH.o

#$CROSS/$ARCH-strip -d -x sqlite3-$ARCH.o

cp sqlite3-$ARCH.o $DST
cp sqlite3-$ARCH.o $DST2

