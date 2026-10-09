FROM perl:5.43.9-slim-bookworm@sha256:32affa4f5f05b5dd03f8d92ae610fa63514417e42e5238231b8815a7e81d9bcb

# expect-dev - provides `unbuffer`
RUN apt-get update && \
    apt-get install -y --no-install-recommends expect-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/test-runner
COPY . .

# Fetch the cpm installer (a single-file Perl script).
ADD https://raw.githubusercontent.com/skaji/cpm/main/cpm /tmp/cpm

# Build the CPAN deps. A C toolchain is needed to compile the XS modules, but it is
# installed and purged within this single layer so the compiler doesn't bloat the
# final image. The cpm build cache is removed too.
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    perl /tmp/cpm install -g --cpanfile /opt/test-runner/cpanfile --snapshot /dev/null && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf "$HOME/.perl-cpm" /usr/share/doc /var/lib/apt/lists/* /tmp/*

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
