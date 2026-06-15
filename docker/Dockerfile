FROM debian:12-slim AS builder

ARG LASTZ_VERSION=1.04.52
ARG LASTZ_SHA256=274bf0d774e3f4da87c23ca0b5cc4269f3dcaecf71a1c6289d426e24fbccf4c8
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    for attempt in 1 2 3 4 5; do \
        if apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
            ca-certificates \
            curl \
            diffutils \
            gcc \
            grep \
            libc6-dev \
            make \
            python3; then \
            break; \
        fi; \
        if [ "$attempt" = 5 ]; then exit 1; fi; \
        apt-get -o Acquire::Retries=5 update; \
        sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/lastz-build

RUN set -eux; \
    curl -fsSL -o lastz.tar.gz "https://github.com/lastz/lastz/archive/refs/tags/${LASTZ_VERSION}.tar.gz"; \
    echo "${LASTZ_SHA256}  lastz.tar.gz" | sha256sum -c -; \
    mkdir src; \
    tar -xzf lastz.tar.gz -C src --strip-components=1

WORKDIR /tmp/lastz-build/src

RUN set -eux; \
    make -j"$(nproc)" build_lastz; \
    make -j"$(nproc)" build_lastz_32; \
    make -j"$(nproc)" build_lastz_40; \
    make test; \
    LASTZ_INSTALL=/opt/lastz/bin make install_lastz install_32 install_40; \
    mkdir -p /opt/lastz/share/doc/lastz /opt/lastz/share/licenses/lastz /opt/lastz/share/lastz /opt/lastz/share/testdata; \
    cp README.md README.lastz.html hsx_format.html lav_format.html /opt/lastz/share/doc/lastz/; \
    cp LICENSE /opt/lastz/share/licenses/lastz/LICENSE; \
    cp -a docs /opt/lastz/share/doc/lastz/docs; \
    cp -a tools tabular_tools /opt/lastz/share/lastz/; \
    cp -a test_data/. /opt/lastz/share/testdata/; \
    find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools -maxdepth 1 -type f \( -name '*.py' -o -name '*.sh' \) -exec sh -c 'for f do if head -n 1 "$f" | grep -q "^#!"; then chmod 0755 "$f"; fi; done' sh {} +; \
    find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools -maxdepth 1 -type f -name '*.py' -print0 | xargs -0 -r python3 -m py_compile

FROM debian:12-slim

ARG LASTZ_VERSION=1.04.52
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    for attempt in 1 2 3 4 5; do \
        if apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
            bash \
            ca-certificates \
            coreutils \
            diffutils \
            grep \
            libc-bin \
            python3 \
            sed; then \
            break; \
        fi; \
        if [ "$attempt" = 5 ]; then exit 1; fi; \
        apt-get -o Acquire::Retries=5 update; \
        sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/lastz /opt/lastz

ENV PATH=/opt/lastz/bin:/opt/lastz/share/lastz/tools:/opt/lastz/share/lastz/tabular_tools:${PATH}

ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=lastz

RUN set -eux; \
    for cmd in lastz lastz_D lastz_32 lastz_40 python3 bash sed grep ldd lav_sort.py maf_sort.py; do \
        command -v "$cmd" >/dev/null; \
    done; \
    lastz --version 2>&1 | grep -F "lastz (version ${LASTZ_VERSION} released 20250402)" >/dev/null; \
    lastz --help 2>&1 | grep -F "target[[start..end]]" >/dev/null; \
    lastz --help 2>&1 | grep -F -- "--format=<type>" >/dev/null; \
    find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools -maxdepth 1 -type f -name '*.py' -print0 | xargs -0 -r python3 -m py_compile; \
    tmp=/tmp/taf-lastz-build-check; \
    rm -rf "$tmp"; \
    mkdir -p "$tmp"; \
    lastz /opt/lastz/share/testdata/pseudocat.fa /opt/lastz/share/testdata/pseudopig.fa C=2 W=8 T=0 --format=lav > "$tmp/out.lav"; \
    test -s "$tmp/out.lav"; \
    grep -F "#:lav" "$tmp/out.lav" >/dev/null; \
    lastz /opt/lastz/share/testdata/pseudocat.fa /opt/lastz/share/testdata/pseudopig.fa C=2 W=8 T=0 --format=axt > "$tmp/out.axt"; \
    test -s "$tmp/out.axt"; \
    lastz /opt/lastz/share/testdata/pseudocat.fa /opt/lastz/share/testdata/pseudopig.fa C=2 W=8 T=0 --format=maf > "$tmp/out.maf"; \
    grep -F "##maf version=1" "$tmp/out.maf" >/dev/null; \
    lastz_D /opt/lastz/share/testdata/pseudocat.fa /opt/lastz/share/testdata/pseudopig.fa C=2 W=8 T=0 > "$tmp/out_D.lav"; \
    test -s "$tmp/out_D.lav"; \
    lastz_32 /opt/lastz/share/testdata/pseudocat.fa /opt/lastz/share/testdata/pseudopig.fa C=2 W=8 T=0 --format=sam- > "$tmp/out.sam"; \
    test -s "$tmp/out.sam"; \
    lastz_40 /opt/lastz/share/testdata/pseudocat.fa /opt/lastz/share/testdata/pseudopig.fa C=2 W=8 T=0 --format=paf > "$tmp/out.paf"; \
    test -s "$tmp/out.paf"; \
    rm -rf "$tmp"; \
    for cmd in lastz lastz_D lastz_32 lastz_40; do ldd "$(command -v "$cmd")"; done > /tmp/lastz-ldd.txt; \
    if grep -F "not found" /tmp/lastz-ldd.txt; then exit 1; fi; \
    rm -f /tmp/lastz-ldd.txt
