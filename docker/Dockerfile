ARG LASTZ_VERSION=1.04.60
ARG LASTZ_SHA256=e66bb419a6599861b1d48c3b209d3746e8008c3ddde33f0dfeaa76e634bccebf

FROM debian:12-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171 AS builder

ARG LASTZ_VERSION
ARG LASTZ_SHA256
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      binutils \
      ca-certificates \
      curl \
      diffutils \
      gcc \
      grep \
      libc6-dev \
      make \
      python3; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/lastz-build

COPY docker/patch-python3-helpers.py /usr/local/bin/patch-python3-helpers.py

RUN set -eux; \
    curl --retry 5 --retry-all-errors --connect-timeout 30 -fsSL \
      -o lastz.tar.gz \
      "https://github.com/lastz/lastz/archive/refs/tags/${LASTZ_VERSION}.tar.gz"; \
    echo "${LASTZ_SHA256}  lastz.tar.gz" | sha256sum -c -; \
    mkdir src; \
    tar -xzf lastz.tar.gz -C src --strip-components=1; \
    python3 /usr/local/bin/patch-python3-helpers.py /tmp/lastz-build/src

WORKDIR /tmp/lastz-build/src

RUN set -eux; \
    make -j"$(nproc)" build_lastz; \
    make -j"$(nproc)" build_lastz_32; \
    make -j"$(nproc)" build_lastz_40; \
    make test; \
    LASTZ_INSTALL=/opt/lastz/bin make install_lastz install_32 install_40; \
    strip --strip-unneeded /opt/lastz/bin/lastz /opt/lastz/bin/lastz_D \
      /opt/lastz/bin/lastz_32 /opt/lastz/bin/lastz_40; \
    mkdir -p /opt/lastz/share/doc/lastz /opt/lastz/share/licenses/lastz \
      /opt/lastz/share/lastz /opt/lastz/share/testdata; \
    cp README.md README.lastz.html hsx_format.html lav_format.html /opt/lastz/share/doc/lastz/; \
    cp LICENSE /opt/lastz/share/licenses/lastz/LICENSE; \
    cp -a docs /opt/lastz/share/doc/lastz/docs; \
    cp -a tools tabular_tools /opt/lastz/share/lastz/; \
    cp -a test_data/. /opt/lastz/share/testdata/; \
    find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools \
      -maxdepth 1 -type f \( -name '*.py' -o -name '*.sh' \) \
      -exec sh -c 'for file do if head -n 1 "$file" | grep -q "^#!"; then chmod 0755 "$file"; fi; done' sh {} +; \
    test "$(find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools \
      -maxdepth 1 -type f -name '*.py' | wc -l)" -eq 23; \
    test "$(find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools \
      -maxdepth 1 -type f -perm /111 | wc -l)" -eq 22; \
    mkdir -p /tmp/taf-lastz-builder-pycache; \
    find /opt/lastz/share/lastz/tools /opt/lastz/share/lastz/tabular_tools \
      -maxdepth 1 -type f -name '*.py' -print0 \
      | xargs -0 -r env PYTHONPYCACHEPREFIX=/tmp/taf-lastz-builder-pycache python3 -m py_compile; \
    test "$(find /tmp/taf-lastz-builder-pycache/opt/lastz/share/lastz \
      -type f -name '*.pyc' | wc -l)" -eq 23; \
    rm -rf /tmp/taf-lastz-builder-pycache; \
    test -z "$(find /opt/lastz -type d -name __pycache__ -print -quit)"; \
    { \
      echo "LASTZ ${LASTZ_VERSION}"; \
      echo "Source: https://github.com/lastz/lastz/archive/refs/tags/${LASTZ_VERSION}.tar.gz"; \
      echo "SHA256: ${LASTZ_SHA256}"; \
      echo "Python 3 compatibility: strict package patch applied."; \
      echo "Packaging: four upstream ELF binaries stripped; command and helper surfaces unchanged."; \
    } > /opt/lastz/share/doc/lastz/source.txt

FROM debian:12-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash \
      coreutils \
      findutils \
      grep \
      libc-bin \
      python3 \
      sed; \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/lastz /opt/lastz
COPY --chmod=0755 docker/smoke.sh /usr/local/bin/taf-lastz-smoke

ENV PATH=/opt/lastz/bin:/opt/lastz/share/lastz/tools:/opt/lastz/share/lastz/tabular_tools:${PATH}
ENV PYTHONDONTWRITEBYTECODE=1

RUN set -eux; \
    for command in lastz lastz_D lastz_32 lastz_40 lav_sort.py maf_sort.py \
      build_fasta_hsx.py pick_from_fasta_hsx.py tabular_to_maf.py; do \
      command -v "$command" >/dev/null; \
    done; \
    bash -n /opt/lastz/share/lastz/tools/create_scores_file.sh; \
    taf-lastz-smoke source; \
    taf-lastz-smoke versions; \
    taf-lastz-smoke pycompile

WORKDIR /work

ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=lastz
