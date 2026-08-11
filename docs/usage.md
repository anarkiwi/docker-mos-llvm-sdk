# Usage

## Direct

    docker run --rm -u $(id -u):$(id -g) -v $PWD:/work \
      ghcr.io/anarkiwi/docker-mos-llvm-sdk:latest mos-c64-clang -Os -o hello.prg hello.c

`-u` keeps build artifacts owned by the calling user. The current directory is mounted at
`/work`, which is also the image working directory, so relative paths behave as they do
natively. Paths outside the mount (e.g. absolute include paths) are not visible to the
container; mount them explicitly with `MOS_DOCKER_OPTS`.

## Wrapper

`bin/mos-docker` runs one SDK tool per invocation. Copy it onto `PATH`, then either pass the
tool name, or symlink the script to the tool name and call the symlink:

    mos-docker mos-c64-clang -Os -o hello.prg hello.c
    ln -s mos-docker mos-c64-clang && ./mos-c64-clang -Os -o hello.prg hello.c

| Variable | Default | Purpose |
| --- | --- | --- |
| `MOS_IMAGE` | `ghcr.io/anarkiwi/docker-mos-llvm-sdk:latest` | image and tag to run |
| `MOS_DOCKER` | `docker` | container runtime (e.g. `podman`) |
| `MOS_DOCKER_OPTS` | empty | extra `docker run` arguments, e.g. `-v /opt/inc:/opt/inc` |

Pin `MOS_IMAGE` to a version tag in projects that must build reproducibly.

## Makefile

Replace absolute SDK paths with a container invocation:

```make
MOS_IMAGE := ghcr.io/anarkiwi/docker-mos-llvm-sdk:v23.0.1
MOS := docker run --rm -u $(shell id -u):$(shell id -g) -v $(CURDIR):/work $(MOS_IMAGE)

vap.prg: $(SOURCES)
	$(MOS) mos-c64-clang $(CFLAGS) -o $@ $<
```

Recipes that already use `mos-c64-clang` unqualified need no edit if `bin/mos-docker` is
symlinked to that name on `PATH`.

Only the SDK is in the image. Emulator and disk tools such as VICE's `c1541` and `petcat`
remain host dependencies.

## Tools

All upstream SDK binaries are present under `/usr/local/llvm-mos/bin`, including the
per-target drivers (`mos-c64-clang`, `mos-c128-clang`, `mos-nes-nrom-clang`, `mos-cx16-clang`,
`mos-mega65-clang`, ...), `clang`, `clang-format`, `clangd`, `clang-tidy`, `ld.lld`,
`llvm-objcopy`, and `llvm-mlb`. List them with:

    docker run --rm ghcr.io/anarkiwi/docker-mos-llvm-sdk:latest ls /usr/local/llvm-mos/bin
