#!/bin/sh

set -e

export CURDIR="$PWD/`dirname $0`"

if [ `uname` = 'Linux' ]; then
  sudo apt install -y cmake clang binutils-gold bc libssl-dev
  sudo rm /usr/bin/ld && sudo ln -s /usr/bin/ld.gold /usr/bin/ld
  export CPUS=`grep -c ^processor /proc/cpuinfo`
elif [ `uname` = 'FreeBSD' ]; then
  sudo pkg install -y git cmake wget
  sudo ln -s /usr/local/bin/perl /usr/bin/perl
  export CPUS=`sysctl -n hw.ncpu`
elif [ `uname` = 'Darwin' ]; then
  export CPUS=`sysctl -n hw.ncpu`
else
  export CPUS=1
fi

wget http://releases.llvm.org/4.0.0/llvm-4.0.0.src.tar.xz
wget http://releases.llvm.org/4.0.0/cfe-4.0.0.src.tar.xz

tar -xf llvm-4.0.0.src.tar.xz
tar -xf cfe-4.0.0.src.tar.xz

mv llvm-4.0.0.src llvm
mv cfe-4.0.0.src llvm/tools/clang

rm llvm-4.0.0.src.tar.xz cfe-4.0.0.src.tar.xz

cd llvm/tools/clang
patch -p2 < $CURDIR/D28445.diff
patch -p2 < $CURDIR/D30289.diff
patch -p0 < $CURDIR/D30406.diff
patch -p0 < $CURDIR/D30909.diff
patch -p3 < $CURDIR/taint.patch
ln -s $CURDIR/MachInterface.h include/clang/StaticAnalyzer/Checkers/MachInterface.h
cd ../../..

mkdir build
cd build

cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 ../llvm
make -j $CPUS
