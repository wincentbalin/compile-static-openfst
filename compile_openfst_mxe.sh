#!/bin/sh -e
#
# Compile OpenFST and OpenGRM both for win32 and for win64

OPENFST_VERSION=1.6.9
BAUMWELCH_VERSION=0.2.5
CATEGORIAL_VERSION=1.3.3
OPENGRM_NGRAM_VERSION=1.3.4
THRAX_VERSION=1.2.7

SCRIPT_FILENAME=`readlink -f $0`

# Set amount of MXE parallel compiling jobs
if [ "$JOBS" = "" ]
then
  JOBS=1
  export JOBS
fi

# Set MXE path
if [ "$MXE" = "" ]
then
  MXE=/opt/mxe
  export MXE
fi

# Check MXE path
if [ ! -d "$MXE" ]
then
  echo MXE not found in $MXE
  echo Please set the variable $MXE to the path of MXE!
  exit 1
fi

# Go to MXE directory and compile the dependencies
echo Preparing MXE...
(cd "$MXE" && make MXE_TARGETS='x86_64-w64-mingw32.static i686-w64-mingw32.static' JOBS=$JOBS cc mman-win32 zlib readline)

# Download function
ARCHIVE_DIR=`dirname "$SCRIPT_FILENAME"`/archives
CURRENT_DIR=`pwd`
download_source()
{
  if [ ! -d "$ARCHIVE_DIR" ]
  then
    mkdir -p "$ARCHIVE_DIR"
  fi

  cd "$ARCHIVE_DIR" && \
  wget -N $2/$1 && \
  cd "$CURRENT_DIR"
}

# Adjust PATH
PATH=$MXE/usr/bin:$PATH
export PATH

# Compile for Win32
CROSS_ARCH=i686-w64-mingw32.static
PREFIX="$CURRENT_DIR/win32"

# Install headers from mingw-std-threads
download_source master.zip https://github.com/meganz/mingw-std-threads/archive/

unzip "$ARCHIVE_DIR/master.zip"
if [ -d mingw-std-threads ]
then
  rm -r mingw-std-threads
fi
mv mingw-std-threads-master mingw-std-threads

# Compile OpenFST
download_source openfst-$OPENFST_VERSION.tar.gz http://www.openfst.org/twiki/pub/FST/FstDownload/

tar zxvf $ARCHIVE_DIR/openfst-$OPENFST_VERSION.tar.gz && \
cd openfst-$OPENFST_VERSION && \
patch -p0 < ../lock.patch && \
patch -p0 < ../mapped-file-mxe.patch && \
CPPFLAGS="-DWINDOWS -DFST_NO_DYNAMIC_LINKING -DMMAN_LIBRARY -I$CURRENT_DIR" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
LDFLAGS="-lmman" \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared \
    --enable-compact-fsts --enable-compress --enable-const-fsts --enable-far --enable-linear-fsts \
    --enable-lookahead-fsts --enable-mpdt --enable-ngram-fsts --enable-pdt --enable-special \
    --enable-bin --enable-grm && \
make -j$JOBS && \
make install && \
cd ..

# Compile Baum-Welch extension
download_source baumwelch-$BAUMWELCH_VERSION.tar.gz http://openfst.org/twiki/pub/Contrib/FstContrib/

tar zxvf $ARCHIVE_DIR/baumwelch-$BAUMWELCH_VERSION.tar.gz && \
cd baumwelch-$BAUMWELCH_VERSION && \
patch -p0 < ../baumwelch.patch && \
CPPFLAGS="-I$CURRENT_DIR -I$PREFIX/include -DFST_NO_DYNAMIC_LINKING -std=c++11" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
LDFLAGS="-L$PREFIX/lib" \
ac_cv_lib_dl_dlopen=no \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared --enable-bin && \
make -j$JOBS LDADD="../script/libbaumwelchscript.la -lfstfarscript -lfstfar -lfstscript -lfst" && \
make install && \
cd ..

# Compile categorial extension
download_source categorial-$CATEGORIAL_VERSION.tar.gz http://openfst.org/twiki/pub/Contrib/FstContrib/

tar zxvf $ARCHIVE_DIR/categorial-$CATEGORIAL_VERSION.tar.gz && \
cd categorial-$CATEGORIAL_VERSION && \
./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared && \
make -j$JOBS && \
make install && \
cd ..

# Compile OpenGRM NGram
download_source opengrm-ngram-$OPENGRM_NGRAM_VERSION.tar.gz http://www.openfst.org/twiki/pub/GRM/NGramDownload/

tar zxvf $ARCHIVE_DIR/opengrm-ngram-$OPENGRM_NGRAM_VERSION.tar.gz && \
cd opengrm-ngram-$OPENGRM_NGRAM_VERSION && \
CPPFLAGS="-I$CURRENT_DIR -I$PREFIX/include -DFST_NO_DYNAMIC_LINKING -std=c++11" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions -Wa,-mbig-obj" \
LDFLAGS="-L$PREFIX/lib" \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared && \
make -j$JOBS AM_LDFLAGS="-L/usr/local/lib/fst -lfstfar -lfst -lm" && \
make install && \
cd ..

# Compile OpenGRM Thrax
download_source thrax-$THRAX_VERSION.tar.gz http://www.openfst.org/twiki/pub/GRM/ThraxDownload/

tar zxvf $ARCHIVE_DIR/thrax-$THRAX_VERSION.tar.gz && \
cd thrax-$THRAX_VERSION && \
patch -p0 < ../thrax-configure-mingw.patch && \
patch -p0 < ../thrax-utils-mingw.patch && \
patch -p0 < ../thrax-cdrewrite-mingw.patch && \
patch -p0 < ../thrax-rewrite-tester-utils-h-mingw.patch && \
patch -p0 < ../thrax-rewrite-tester-utils-cc-mingw.patch && \
patch -p0 < ../thrax-utildefs-h-mingw.patch && \
patch -p0 < ../thrax-utildefs-cc-mingw.patch && \
patch -p0 < ../thrax-random-generator-cc-mingw.patch && \
CPPFLAGS="-I$CURRENT_DIR -I$PREFIX/include -DFST_NO_DYNAMIC_LINKING -std=c++11" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
LDFLAGS="-L$PREFIX/lib" \
LIBS="-ltermcap" \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared --enable-bin --enable-readline && \
make LDADD="-L/usr/local/lib/fst ../lib/libthrax.la -lfstfar -lfst -lm -lreadline" && \
make install && \
cd ..

# Strip binaries
$CROSS_ARCH-strip $PREFIX/bin/*

# Create zip archive
(cd $PREFIX && zip -rv9 ../openfst-ngram-thrax-win32.zip *)

# Remove source directories
rm -rf openfst-$OPENFST_VERSION
rm -rf baumwelch-$BAUMWELCH_VERSION
rm -rf categorial-$CATEGORIAL_VERSION
rm -rf opengrm-ngram-$OPENGRM_NGRAM_VERSION
rm -rf thrax-$THRAX_VERSION

# Compile for Win64
CROSS_ARCH=x86_64-w64-mingw32.static
PREFIX="$CURRENT_DIR/win64"

# Compile OpenFST
tar zxvf $ARCHIVE_DIR/openfst-$OPENFST_VERSION.tar.gz && \
cd openfst-$OPENFST_VERSION && \
patch -p0 < ../lock.patch && \
patch -p0 < ../mapped-file-mxe.patch && \
CPPFLAGS="-DWINDOWS -DFST_NO_DYNAMIC_LINKING -DMMAN_LIBRARY -I$CURRENT_DIR" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
LDFLAGS="-lmman" \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared \
    --enable-compact-fsts --enable-compress --enable-const-fsts --enable-far --enable-linear-fsts \
    --enable-lookahead-fsts --enable-mpdt --enable-ngram-fsts --enable-pdt --enable-special \
    --enable-bin --enable-grm && \
make -j$JOBS && \
make install && \
cd ..

# Compile Baum-Welch extension
tar zxvf $ARCHIVE_DIR/baumwelch-$BAUMWELCH_VERSION.tar.gz && \
cd baumwelch-$BAUMWELCH_VERSION && \
patch -p0 < ../baumwelch.patch && \
CPPFLAGS="-I$CURRENT_DIR -I$PREFIX/include -DFST_NO_DYNAMIC_LINKING -std=c++11" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
LDFLAGS="-L$PREFIX/lib" \
ac_cv_lib_dl_dlopen=no \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared --enable-bin && \
make -j$JOBS LDADD="../script/libbaumwelchscript.la -lfstfarscript -lfstfar -lfstscript -lfst" && \
make install && \
cd ..

# Compile categorial extension
tar zxvf $ARCHIVE_DIR/categorial-$CATEGORIAL_VERSION.tar.gz && \
cd categorial-$CATEGORIAL_VERSION && \
./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared && \
make -j$JOBS && \
make install && \
cd ..

# Compile OpenGRM NGram
tar zxvf $ARCHIVE_DIR/opengrm-ngram-$OPENGRM_NGRAM_VERSION.tar.gz && \
cd opengrm-ngram-$OPENGRM_NGRAM_VERSION && \
CPPFLAGS="-I$CURRENT_DIR -I$PREFIX/include -DFST_NO_DYNAMIC_LINKING -std=c++11" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions -Wa,-mbig-obj" \
LDFLAGS="-L$PREFIX/lib" \
ac_cv_lib_dl_dlopen=no \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared && \
make -j$JOBS AM_LDFLAGS="-lfstfar -lfst" && \
make install && \
cd ..

# Compile OpenGRM Thrax
tar zxvf $ARCHIVE_DIR/thrax-$THRAX_VERSION.tar.gz && \
cd thrax-$THRAX_VERSION && \
patch -p0 < ../thrax-configure-mingw.patch && \
patch -p0 < ../thrax-utils-mingw.patch && \
patch -p0 < ../thrax-cdrewrite-mingw.patch && \
patch -p0 < ../thrax-rewrite-tester-utils-h-mingw.patch && \
patch -p0 < ../thrax-rewrite-tester-utils-cc-mingw.patch && \
patch -p0 < ../thrax-utildefs-h-mingw.patch && \
patch -p0 < ../thrax-utildefs-cc-mingw.patch && \
patch -p0 < ../thrax-random-generator-cc-mingw.patch && \
CPPFLAGS="-I$CURRENT_DIR -I$PREFIX/include -DFST_NO_DYNAMIC_LINKING -std=c++11" \
CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
LDFLAGS="-L$PREFIX/lib" \
LIBS="-ltermcap" \
  ./configure --prefix="$PREFIX" --host=$CROSS_ARCH --enable-static --disable-shared --enable-bin --enable-readline && \
make LDADD="../lib/libthrax.la -lfstfar -lfst -lreadline" && \
make install && \
cd ..

# Strip binaries
$CROSS_ARCH-strip $PREFIX/bin/*

# Create zip archive
(cd $PREFIX && zip -rv9 ../openfst-ngram-thrax-win64.zip *)

# Remove source directories
rm -rf openfst-$OPENFST_VERSION
rm -rf baumwelch-$BAUMWELCH_VERSION
rm -rf categorial-$CATEGORIAL_VERSION
rm -rf opengrm-ngram-$OPENGRM_NGRAM_VERSION
rm -rf thrax-$THRAX_VERSION

# Everything compiled
echo Done!

