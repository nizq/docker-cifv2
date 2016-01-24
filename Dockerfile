FROM alpine:3.3

MAINTAINER nizq <ni.zhiqiang@gmail.com>

RUN echo "===> Adding base packages..." \
    && apk add --update libffi libzmq perl perl openssl expat gettext libxml2

RUN echo "===> Adding dev tools..." \
    && apk add --update make wget libffi-dev gcc libc-dev perl-dev \
        curl openssl-dev autoconf automake libtool \
        expat-dev libxml2-dev git

RUN echo "===> Installing perl modules..." \
    && curl -L https://cpanmin.us | perl - App::cpanminus \
    && cpanm --notest Regexp::Common Moo@1.007000 Mouse@2.4.1 ZMQ::FFI@0.17 \
        Log::Log4perl@1.44 Test::Exception@0.32 MaxMind::DB::Reader@0.050005 \
        GeoIP2@0.040005 Hijk@0.19 Crypt::Random::Source Compress::Snappy \
        Carp::Assert DateTime::Format::DateParse Daemon::Control XML::RSS \
        XML::LibXML File::Slurp HTML::TableExtract String::Tokenizer File::Type \
        Search::Elasticsearch@1.19 \
    && cpanm --notest https://github.com/csirtgadgets/ZMQx-Class/archive/master.tar.gz \
    && cpanm --notest https://github.com/csirtgadgets/p5-cif-sdk/archive/2.00_33.tar.gz \
    && cpanm --notest https://github.com/kraih/mojo/archive/v5.82.tar.gz \
    && cpanm --notest http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/local-lib-2.000015.tar.gz

WORKDIR /root
RUN echo "===> Downloading CIFv2..." \
    && git clone https://github.com/csirtgadgets/massive-octo-spice.git mos \
    && cd mos/contrib \
    && wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz \
    && gunzip GeoLite2-City.mmdb.gz

WORKDIR /root/mos
RUN echo "===> Building CIFv2..." \
    && ./autogen.sh \
    && ./configure --enable-geoip --sysconfdir=/etc/cif --localstatedir=/var/cif --prefix=/opt/cif \
    && mkdir -p /var/cif/cache \
    && make && make install

RUN echo "===> Cleaning..." \
    && apk del openssl-dev libc-dev perl-dev expat-dev libxml2-dev autoconf automake libtool git \
    && rm -rf /var/cache/apk/* \
    && rm -rf /root/mos

ENV CIF_HOME=/opt/cif
ENV PATH=$CIF_HOME/bin:$PATH
ENV PERL5LIB=/opt/cif/lib/perl5
ENV DATA_DIR=/var/cif
ENV LOG_DIR=/var/log/cif
ENV CONF_DIR=/etc/cif

VOLUME ["/etc/cif", "/var/cif", "/var/log/cif"]

