FROM perl:5.38.0-bookworm

RUN apt-get update && \
    apt-get install -y npm && \
    apt-get purge --auto-remove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g \
    App::cpm \
    Test2::V0 \
    App::Yath \
    Data::Dumper \
    Data::Dump \
    Moo \
    Cpanel::JSON::XS \
    Path::Tiny

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
