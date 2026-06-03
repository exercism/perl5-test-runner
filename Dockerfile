FROM perl:5.42.2-slim-bookworm@sha256:49f4e5e7e2fc5b12e5fc9b5a0603d96502feb24b97babd1bdf42e3f1fc3ebc43

RUN apt-get update && \
    apt-get install -y curl npm expect-dev && \
    apt-get purge --auto-remove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .
RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g --cpanfile /opt/test-runner/cpanfile --snapshot /dev/null

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
