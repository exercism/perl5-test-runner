FROM perl:5.40.0-bookworm

RUN apt-get update && \
    apt-get install -y npm expect-dev && \
    apt-get purge --auto-remove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .
RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g --cpanfile /opt/test-runner/cpanfile --snapshot /dev/null

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
