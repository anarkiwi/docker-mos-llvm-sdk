# docker-mos-llvm-sdk

[llvm-mos SDK](https://github.com/llvm-mos/llvm-mos-sdk) 6502 cross compiler toolchain as a
container image, so 6502 projects build without installing the SDK in `/usr/local`.

Image versions match the upstream SDK release exactly: image `v23.0.1` contains SDK `v23.0.1`.

## Images

    ghcr.io/anarkiwi/docker-mos-llvm-sdk:v23.0.1
    docker.io/anarkiwi/mos-llvm-sdk:v23.0.1

Tags: `vX.Y.Z`, `X.Y.Z`, `latest`. linux/amd64 only (upstream ships no other Linux binaries).

## Use

Tools are on `PATH`; the working directory is `/work`.

    docker run --rm -u $(id -u):$(id -g) -v $PWD:/work \
      ghcr.io/anarkiwi/docker-mos-llvm-sdk:latest \
      mos-c64-clang -Os -o hello.prg hello.c

`bin/mos-docker` wraps that call, and acts as the named tool when symlinked to one:

    ln -s mos-docker mos-c64-clang
    ./mos-c64-clang -Os -o hello.prg hello.c

See [docs/usage.md](docs/usage.md) for Makefile integration and wrapper options,
[docs/releasing.md](docs/releasing.md) for the release and upstream tracking workflows.

## Test

    docker build -t mos-llvm-sdk:test .
    tests/smoke.sh mos-llvm-sdk:test
