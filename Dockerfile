FROM perl:5.42.2-slim-bookworm@sha256:49f4e5e7e2fc5b12e5fc9b5a0603d96502feb24b97babd1bdf42e3f1fc3ebc43

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
