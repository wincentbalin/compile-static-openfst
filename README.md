# Attention: this is an archived repository!

As time goes by, the OpenFST 1.8.1 (or maybe even earlier versions) stopped cross-compiling. Already the `configure` script tells you so.

Hence, remembering the original cause of this little project, specifically being able to work with [OpenFST](https://www.openfst.org/) and [OpenGRM](https://www.opengrm.org/) on Windows, I decided to steer everyone with the same cause to another project of mine, [opengrm-vagrant](https://github.com/wincentbalin/opengrm-vagrant), which enables the same, even in three different ways:

1. Use `Vagrantfile` to configure a working environment
2. Use `Dockerfile` to create a Docker container
3. Use the shell script `install-opengrm.sh` with WSL (Windows Subsystem for Linux) to have an almost native environment

As implied above, this project will not be developed anymore.

----

# OpenFST + OpenGRM-NGram + Thrax compilation for Windows using MinGW

The script `compile_openfst.sh` compiles static Windows binaries of [OpenFST](http://openfst.org), [OpenGRM-NGram](http://www.opengrm.org/twiki/bin/view/GRM/NGramLibrary) and [Thrax](http://www.opengrm.org/twiki/bin/view/GRM/Thrax) using the included `Dockerfile`.

## Software versions

You can see the versions of the compiled libraries in the `Dockerfile`. Just search therein for the string `ENV OPENFST_VERSION`.

## Prerequisites

Ensure that your Docker host has at least 3 GB RAM! This is required when compiling OpenFST and/or Thrax.

## Results

The script/`Dockerfile` combination compiles both 32-bit and 64-bit binaries. After compilation, all resulting files are compressed to a `.zip`-file and are exported into the working directory of the script. The 32-bit binaries land in the `openfst+ngram+thrax-mingw32.zip`, the 64-bit binaries in the `openfst+ngram+thrax-mingw64.zip` respectively.

The binaries are static and thus self-sufficient. They reside in the `bin` directory in the archive.

In the directory `lib` you will find only static libraries (`.a` and `.la` files) for further developments.

Other directories contain supplementary files.
