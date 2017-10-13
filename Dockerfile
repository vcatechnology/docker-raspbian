FROM resin/raspberry-pi-debian
MAINTAINER VCA Technology <developers@vcatechnology.com>

# Start emulation: https://docs.resin.io/runtime/resin-base-images/
RUN [ "cross-build-start" ]

# Build-time metadata as defined at http://label-schema.org
ARG PROJECT_NAME
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="$PROJECT_NAME" \
      org.label-schema.description="A raspbian image that is updated daily to have all the latest packages" \
      org.label-schema.url="https://www.debian.org/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vcatechnology/docker-raspbian" \
      org.label-schema.vendor="VCA Technology" \
      org.label-schema.version=$VERSION \
      org.label-schema.license=MIT \
      org.label-schema.schema-version="1.0"

# Make sure APT operations are non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Create install script
RUN touch                                                                 /usr/local/bin/vca-install-package \
 && chmod +x                                                              /usr/local/bin/vca-install-package \
 && echo '#! /bin/sh'                                                  >> /usr/local/bin/vca-install-package \
 && echo 'set -e'                                                      >> /usr/local/bin/vca-install-package \
 && echo 'apt-get -q update'                                           >> /usr/local/bin/vca-install-package \
 && echo 'apt-get -qy -o Dpkg::Options::="--force-confnew" install $@' >> /usr/local/bin/vca-install-package \
 && echo 'apt-get -qy clean'                                           >> /usr/local/bin/vca-install-package

# Create uninstall script
RUN touch                                   /usr/local/bin/vca-uninstall-package \
 && chmod +x                                /usr/local/bin/vca-uninstall-package \
 && echo '#! /bin/sh'                    >> /usr/local/bin/vca-uninstall-package \
 && echo 'set -e'                        >> /usr/local/bin/vca-uninstall-package \
 && echo 'apt-get -qy remove --purge $@' >> /usr/local/bin/vca-uninstall-package \
 && echo 'apt-get -qy autoremove'        >> /usr/local/bin/vca-uninstall-package \
 && echo 'apt-get -qy clean'             >> /usr/local/bin/vca-uninstall-package

# Generate locales
RUN vca-install-package apt-utils locales \
 && sed -i 's/^# \(en_GB.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
 && echo 'LANG="en_GB.UTF-8"' > /etc/default/locale \
 && dpkg-reconfigure locales \
 && update-locale LANG=en_GB.UTF-8

# Set up the timezone
RUN vca-install-package tzdata \
 && echo "Europe/London" > /etc/timezone \
 && dpkg-reconfigure tzdata

# Update all packages
RUN apt-get -q update \
 && apt-get -qy -o Dpkg::Options::="--force-confnew" dist-upgrade \
 && apt-get -qy autoremove \
 && apt-get -q clean

# Install the NodeSource repository as Node/NPM are unsupported on Stretch
RUN vca-install-package gnupg curl \
 && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
 && vca-uninstall-package curl

# Stop emulation
RUN [ "cross-build-end" ]
