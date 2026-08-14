#!/bin/sh
# Smoke test an llvm-mos SDK image: tests/smoke.sh <image> [expected-version]
set -eu

image=${1:?usage: smoke.sh <image> [expected-version]}
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
expected=${2:-$(sed -n 's/^ARG LLVM_MOS_VERSION=//p' "${here}/../Dockerfile")}
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
cp "${here}/hello.c" "${work}/"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok: $*"; }

run() {
  docker run --rm -u "$(id -u):$(id -g)" -v "${work}:/work" -w /work "${image}" "$@"
}

magic() { od -An -tx1 -N "$2" "$1" | tr -d ' \n'; }

got=$(docker run --rm "${image}" sh -c 'printf %s "$LLVM_MOS_VERSION"')
[ "${got}" = "${expected}" ] || fail "image LLVM_MOS_VERSION ${got} != ${expected}"
ok "version ${got}"

# llvm-mos tracks LLVM main, so the clang major is independent of the SDK tag
# (SDK v22.7.1 and v23.0.1 both ship clang 23; v23.1.0 ships clang 24).
clang_version=$(run mos-clang --version \
  | sed -n 's/.*clang version \([0-9][^ ]*\).*/\1/p')
[ -n "${clang_version}" ] || fail "mos-clang did not report a clang version"
ok "clang version ${clang_version}"

for tool in mos-c64-clang mos-c64-clang++ mos-nes-clang mos-cx16-clang \
            mos-mega65-clang llvm-objcopy ld.lld llvm-mlb; do
  run "${tool}" --version >/dev/null 2>&1 || fail "missing tool ${tool}"
done
ok "toolchain binaries present"

run mos-c64-clang -Os -o hello.prg hello.c || fail "c64 compile"
[ "$(magic "${work}/hello.prg" 2)" = "0108" ] || fail "hello.prg lacks \$0801 load address"
ok "c64 prg built ($(wc -c <"${work}/hello.prg") bytes)"

run mos-nes-nrom-clang -Os -o hello.nes hello.c || fail "nes compile"
[ "$(magic "${work}/hello.nes" 4)" = "4e45531a" ] || fail "hello.nes lacks iNES header"
ok "nes rom built"

[ "$(find "${work}/hello.prg" -user "$(id -un)" | wc -l)" = 1 ] \
  || fail "artifacts not owned by calling user"
ok "artifact ownership"

# Wrapper script, both invocation styles.
ln -s "${here}/../bin/mos-docker" "${work}/mos-c64-clang"
(cd "${work}" && MOS_IMAGE="${image}" "${here}/../bin/mos-docker" \
  mos-c64-clang -Os -o wrapped.prg hello.c) || fail "mos-docker tool arg"
(cd "${work}" && MOS_IMAGE="${image}" ./mos-c64-clang -Os -o linked.prg hello.c) \
  || fail "mos-docker symlink"
cmp "${work}/wrapped.prg" "${work}/linked.prg" || fail "wrapper outputs differ"
ok "mos-docker wrapper"

echo "PASS ${image} (${expected})"
