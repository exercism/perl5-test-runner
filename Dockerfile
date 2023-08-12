FROM perl:5.38.0-bookworm

RUN apt-get update && \
    apt-get install -y npm expect-dev && \
    apt-get purge --auto-remove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g \
    App::cpm \
    Cpanel::JSON::XS \
    Path::Tiny \
    Test2::V0 \
    App::Yath \
    Readonly \
    Data::Dumper \
    Data::Dump \
    Data::Dump::Color \
    XXX \
    Moo \
    Mo \
    Moose \
    Object::Pad \
    Object::Tiny \
    Role::Tiny \
    Type::Tiny

RUN npm install -g tap-parser


WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
