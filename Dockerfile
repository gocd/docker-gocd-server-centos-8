# Copyright 2020 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM alpine:latest as gocd-server-unzip
ARG UID=1000
RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/20.5.0-11820/generic/go-server-20.5.0-11820.zip" > /tmp/go-server-20.5.0-11820.zip
RUN unzip /tmp/go-server-20.5.0-11820.zip -d /
RUN mkdir -p /go-server/wrapper /go-server/bin && \
    mv /go-server-20.5.0/LICENSE /go-server/LICENSE && \
    mv /go-server-20.5.0/bin/go-server /go-server/bin/go-server && \
    mv /go-server-20.5.0/lib /go-server/lib && \
    mv /go-server-20.5.0/logs /go-server/logs && \
    mv /go-server-20.5.0/run /go-server/run && \
    mv /go-server-20.5.0/wrapper-config /go-server/wrapper-config && \
    mv /go-server-20.5.0/wrapper/wrapper-linux* /go-server/wrapper/ && \
    mv /go-server-20.5.0/wrapper/libwrapper-linux* /go-server/wrapper/ && \
    mv /go-server-20.5.0/wrapper/wrapper.jar /go-server/wrapper/ && \
    chown -R ${UID}:0 /go-server && chmod -R g=u /go-server

FROM centos:8

LABEL gocd.version="20.5.0" \
  description="GoCD server based on centos version 8" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="20.5.0-11820" \
  gocd.git.sha="1c9b12ac8aa216a2c062fbec4cba18d9cfb8b404"

# the ports that go server runs on
EXPOSE 8153

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

ARG UID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
# add user to root group for gocd to work on openshift
  useradd -u ${UID} -g root -d /home/go -m go && \
  yum install --assumeyes glibc-langpack-en && \
  yum update -y && \
  yum install --assumeyes git mercurial subversion openssh-clients bash unzip curl procps procps-ng coreutils-single && \
  yum clean all && \
  curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk-13.0.2%2B8/OpenJDK13U-jre_x64_linux_hotspot_13.0.2_8.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-server /docker-entrypoint.d /go-working-dir /godata

ADD docker-entrypoint.sh /

COPY --from=gocd-server-unzip /go-server /go-server
# ensure that logs are printed to console output
COPY --chown=go:root logback-include.xml /go-server/config/logback-include.xml
COPY --chown=go:root install-gocd-plugins git-clone-config /usr/local/sbin/

RUN chown -R go:root /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh \
    && chmod -R g=u /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
