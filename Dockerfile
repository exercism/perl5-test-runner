FROM perl:5.32.1-stretch

RUN apt-get update && \
    apt-get install -y jq libtest2-suite-perl && \
    apt-get purge --auto-remove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sL --compressed https://git.io/cpm | \
    perl - install -L /opt-test-runner/perl5 App::cpm local::lib Test2::V0

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
