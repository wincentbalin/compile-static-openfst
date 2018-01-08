# OpenFST + OpenGRM + Thrax compilation for Windows using MinGW

The script `compile_openfst.sh` compiles static Windows binaries of [OpenFST](http://openfst.org), [OpenGRM](http://opengrm.org) and [Thrax](http://openfst.cs.nyu.edu/twiki/bin/view/GRM/Thrax) using the included `Dockerfile`.

## Software versions

You can see the versions of the compiled libraries in the `Dockerfile`. Just search therein for the string `ENV OPENFST_VERSION`.

## Prerequisites

Ensure that your Docker host has at least 3 GB RAM! This is required when compiling OpenFST and/or Thrax.

## Results

The script/`Dockerfile` combination compiles both 32-bit and 64-bit binaries. After compilation, all resulting files are compressed to a `.zip`-file and are exported into the working directory of the script. The 32-bit binaries land in the `openfst+ngram+thrax-mingw32.zip`, the 64-bit binaries in the `openfst+ngram+thrax-mingw64.zip` respectively.

The binaries are static and thus self-sufficient. They reside in the `bin` directory in the archive.

In the directory `lib` you will find only static libraries (`.a` and `.la` files) for further developments.

Other directories contain supplementary files.
