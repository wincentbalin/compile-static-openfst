FROM ubuntu
MAINTAINER Wincent Balin <wincent.balin@gmail.com>

# Update all packages
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y clean && \
    apt-get -y autoremove

# Install compilation prerequisites
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        build-essential \
        mingw-w64 \
        bison \
        man \
        wget \
        unzip \
        zip \
        less && \
    apt-get -y clean

# Enter versions!!!
ENV ZLIB_VERSION 1.2.11
ENV NCURSES_VERSION 6.0
ENV READLINE_VERSION 7.0
ENV OPENFST_VERSION 1.6.7
ENV OPENGRM_NGRAM_VERSION 1.3.4
ENV THRAX_VERSION 1.2.5

# Prepare compilation directories
ENV C /tmp/compile
WORKDIR $C

# Set environment variables
ENV PATH $C/lib:$PATH
ENV PATH $C/bin:$PATH
ENV LD_RUN_PATH $C/lib:$LD_RUN_PATH

ENV CROSS_ARCH i686-w64-mingw32
ENV BUILD_ARCH x86_64-pc-linux-gnu


# Download and compile zlib
RUN wget -q -O - http://sourceforge.net/projects/libpng/files/zlib/$ZLIB_VERSION/zlib-$ZLIB_VERSION.tar.gz | \
    tar zxvf -
WORKDIR zlib-$ZLIB_VERSION
RUN CC=$CROSS_ARCH-gcc ./configure --prefix $C --static && \
    make && \
    make install
WORKDIR ..

# Download and compile mman-win32
RUN wget -O mman-win32-master.zip https://github.com/witwall/mman-win32/archive/master.zip && \
    unzip mman-win32-master.zip
WORKDIR mman-win32-master
RUN chmod 0755 configure && \
    sync && \
    ./configure --prefix=$C --libdir=$C/lib --incdir=$C/include --enable-static --disable-shared --cross-prefix=$CROSS_ARCH- && \
    make && \
    make install
WORKDIR ..

# Prepare mingw-std-threads package
WORKDIR $C/include/mingw-std-threads
RUN for name in condition_varible mutex thread; \
    do \
        wget https://raw.githubusercontent.com/meganz/mingw-std-threads/master/mingw.$name.h; \
    done
WORKDIR $C

# Download and compile OpenFST
RUN wget -q -O - http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-$OPENFST_VERSION.tar.gz | \
    tar zxvf -
WORKDIR openfst-$OPENFST_VERSION

COPY mapped-file.patch .
RUN patch -p0 < mapped-file.patch

COPY lock.patch .
RUN patch -p0 < lock.patch

RUN CPPFLAGS="-DWINDOWS -DFST_NO_DYNAMIC_LINKING -DMMAN_LIBRARY -I$C/include" \
    CXXFLAGS="-O2 -static -static-libgcc -static-libstdc++ -fexceptions" \
    LDFLAGS="-L$C/lib -lmman" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared \
        --enable-compact-fsts --enable-compress --enable-const-fsts --enable-far --enable-linear-fsts \
        --enable-lookahead-fsts --enable-mpdt --enable-ngram-fsts --enable-pdt --enable-special --enable-bin --enable-grm && \
    make && \
    make install
WORKDIR ..

# Download and compile OpenGRM-NGram
RUN wget -q -O - http://www.openfst.org/twiki/pub/GRM/NGramDownload/opengrm-ngram-$OPENGRM_NGRAM_VERSION.tar.gz | \
    tar zxvf -
WORKDIR opengrm-ngram-$OPENGRM_NGRAM_VERSION
RUN CPPFLAGS="-std=c++11 -I$C/include -DFST_NO_DYNAMIC_LINKING" \
    CXXFLAGS="-O2 -static-libgcc -static-libstdc++" \
    LDFLAGS="-L$C/lib" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared && \
    make AM_LDFLAGS="-L$C/lib/fst -lfstfar -lfst -lm" && \
    make install
WORKDIR ..

# Download and compile ncurses (for GNU read line only)
RUN wget -q -O - http://invisible-mirror.net/archives/ncurses/ncurses-$NCURSES_VERSION.tar.gz | \
    tar zxvf -
WORKDIR ncurses-$NCURSES_VERSION

# Patch came from https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-libs/ncurses/files/ncurses-5.9-gcc-5.patch?revision=1.1
COPY ncurses-5.9-gcc-5.patch .
RUN patch -p1 < ncurses-5.9-gcc-5.patch

RUN CXXFLAGS="-O2 -static-libgcc -static-libstdc++" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared \
        --enable-pc-files --enable-colorfgbg --enable-ext-colors --enable-ext-mouse --disable-home-terminfo \
        --enable-database --enable-sp-funcs --enable-term-driver --enable-interop --enable-widec \
        --without-ada --without-cxx-binding --disable-db-install --without-manpages --without-progs --without-tests --without-debug && \
    make && \
    make install    
WORKDIR ..

# Download and compile GNU Readline (needed for thraxrewrite-tester only)
RUN wget -q -O - ftp://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz | \
    tar zxvf -
WORKDIR readline-$READLINE_VERSION

# The patch was originally https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-readline/readline-7.0-mingw.patch
COPY readline-mingw.patch .
RUN patch -p1 < readline-mingw.patch

RUN ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared --enable-multibyte && \
    make && \
    make install
WORKDIR ..

# Download and compile Thrax
RUN wget -q -O - http://www.openfst.org/twiki/pub/GRM/ThraxDownload/thrax-$THRAX_VERSION.tar.gz | \
    tar zxvf -
WORKDIR thrax-$THRAX_VERSION

COPY thrax-configure-mingw.patch .
RUN patch -p0 < thrax-configure-mingw.patch

COPY thrax-utils-mingw.patch .
RUN patch -p0 < thrax-utils-mingw.patch

COPY thrax-cdrewrite-mingw.patch .
RUN patch -p0 < thrax-cdrewrite-mingw.patch

COPY thrax-rewrite-tester-utils-h-mingw.patch .
RUN patch -p0 < thrax-rewrite-tester-utils-h-mingw.patch

COPY thrax-rewrite-tester-utils-cc-mingw.patch .
RUN patch -p0 < thrax-rewrite-tester-utils-cc-mingw.patch

COPY thrax-utildefs-h-mingw.patch .
RUN patch -p0 < thrax-utildefs-h-mingw.patch

COPY thrax-utildefs-cc-mingw.patch .
RUN patch -p0 < thrax-utildefs-cc-mingw.patch

COPY thrax-random-generator-cc-mingw.patch .
RUN patch -p0 < thrax-random-generator-cc-mingw.patch

COPY thrax-features-h-mingw.patch .
RUN patch -p0 < thrax-features-h-mingw.patch

RUN CPPFLAGS="-std=c++11 -I$C/include -DFST_NO_DYNAMIC_LINKING" \
    CXXFLAGS="-O2 -static-libgcc -static-libstdc++" \
    lt_cv_dlopen="LoadLibrary" \
    lt_cv_dlopen_libs="" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared --enable-bin --enable-readline && \
    make LDADD="-L$C/lib/fst ../lib/libthrax.la -lfstfar -lfst -lm -lreadline -lncursesw" && \
    make install
WORKDIR ..

# Strip binaries
RUN $CROSS_ARCH-strip bin/*.exe

# Create mingw32 archive
RUN zip -r -9 openfst+ngram+thrax-mingw32.zip bin/ include/ lib/ share/

# Clean up everything
RUN mv include/mingw-std-threads . && \
    rm -rf bin/ include/* lib/ share/ && \
    mv mingw-std-threads include/

WORKDIR zlib-$ZLIB_VERSION
RUN make distclean
WORKDIR ..

WORKDIR mman-win32-master
RUN make distclean
WORKDIR ..

WORKDIR openfst-$OPENFST_VERSION
RUN make --ignore distclean
WORKDIR ..

WORKDIR opengrm-ngram-$OPENGRM_NGRAM_VERSION
RUN make distclean
WORKDIR ..

WORKDIR ncurses-$NCURSES_VERSION
RUN make distclean
WORKDIR ..

WORKDIR readline-$READLINE_VERSION
RUN make distclean
WORKDIR ..

WORKDIR thrax-$THRAX_VERSION
RUN make distclean
WORKDIR ..


# Set compilation environment to 64-bit
ENV CROSS_ARCH x86_64-w64-mingw32


# Compile zlib
WORKDIR zlib-$ZLIB_VERSION
RUN CC=$CROSS_ARCH-gcc ./configure --prefix $C --static && \
    make && \
    make install
WORKDIR ..

# Compile mman-win32
WORKDIR mman-win32-master
RUN chmod 0755 configure && \
    sync && \
    ./configure --prefix=$C --libdir=$C/lib --incdir=$C/include --enable-static --disable-shared --cross-prefix=$CROSS_ARCH- && \
    make && \
    make install
WORKDIR ..

# Compile OpenFST
WORKDIR openfst-$OPENFST_VERSION
RUN CPPFLAGS="-DWINDOWS -DFST_NO_DYNAMIC_LINKING -DMMAN_LIBRARY -I$C/include" \
    CXXFLAGS="-O2 -static-libgcc -static-libstdc++ -fexceptions" \
    LDFLAGS="-L$C/lib -lmman" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared \
        --enable-compact-fsts --enable-compress --enable-const-fsts --enable-far --enable-linear-fsts \
        --enable-lookahead-fsts --enable-mpdt --enable-ngram-fsts --enable-pdt --enable-special --enable-bin --enable-grm && \
    make && \
    make install
WORKDIR ..

# Compile OpenGRM-NGram
WORKDIR opengrm-ngram-$OPENGRM_NGRAM_VERSION
RUN CPPFLAGS="-std=c++11 -I$C/include -DFST_NO_DYNAMIC_LINKING" \
    CXXFLAGS="-O2 -static-libgcc -static-libstdc++" \
    LDFLAGS="-L$C/lib" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared && \
    make AM_LDFLAGS="-L$C/lib/fst -lfstfar -lfst -lm" && \
    make install
WORKDIR ..

# Compile ncurses (for GNU read line only)
WORKDIR ncurses-$NCURSES_VERSION
RUN CXXFLAGS="-O2 -static-libgcc -static-libstdc++" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared \
        --enable-pc-files --enable-colorfgbg --enable-ext-colors --enable-ext-mouse --disable-home-terminfo \
        --enable-database --enable-sp-funcs --enable-term-driver --enable-interop --enable-widec \
        --without-ada --without-cxx-binding --disable-db-install --without-manpages --without-progs --without-tests --without-debug && \
    make && \
    make install    
WORKDIR ..

# Compile GNU Readline (needed for thraxrewrite-tester only)
WORKDIR readline-$READLINE_VERSION
RUN ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared --enable-multibyte && \
    make && \
    make install
WORKDIR ..

# Compile Thrax
WORKDIR thrax-$THRAX_VERSION
RUN CPPFLAGS="-std=c++11 -I$C/include -DFST_NO_DYNAMIC_LINKING" \
    CXXFLAGS="-O2 -fexceptions -static-libgcc -static-libstdc++" \
    lt_cv_dlopen="LoadLibrary" \
    lt_cv_dlopen_libs="" \
    ./configure --prefix=$C --host=$CROSS_ARCH --build=$BUILD_ARCH --enable-static --disable-shared --enable-bin --enable-readline && \
    make LDADD="-L$C/lib/fst ../lib/libthrax.la -lfstfar -lfst -lm -lreadline -lncursesw" && \
    make install
WORKDIR ..

# Strip binaries
RUN $CROSS_ARCH-strip bin/*.exe

# Create mingw64 archive
RUN zip -r -9 openfst+ngram+thrax-mingw64.zip bin/ include/ lib/ share/
