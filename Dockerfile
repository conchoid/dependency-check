# Docker Hub: conchoid/dependency-check:v12.2.0-1-trixie
FROM debian:trixie-slim

# Preset locale to en_US.UTF-8
RUN apt-get update \
    && apt-get install -y locales git git-lfs ssh \
    && apt-get install -y --no-install-recommends connect-proxy \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG=en_US.utf8

ENV SETUP_HOME=/opt/dependencycheck

RUN apt-get update && apt-get install -y curl

ENV CURL_RETRY_OPT='--retry 3 --max-time 180 --retry-max-time 300'
ENV JVM_PATH=/opt/java/openjdk
RUN mkdir -p ${JVM_PATH}
# Install openjdk11
RUN cd ${JVM_PATH} \
    && curl $CURL_RETRY_OPT -OL "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz" \
    && echo "6e4cead158037cb7747ca47416474d4f408c9126be5b96f9befd532e0a762b47 OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz" | sha256sum -c - \
    && tar zxf "OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz" -C ${JVM_PATH} \
    && rm "OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz"

ENV JAVA_HOME=${JVM_PATH}/jdk-11.0.8+10
ENV JENV_ROOT=/opt/jenv
ENV PATH="${JENV_ROOT}/shims:${JENV_ROOT}/bin:$JAVA_HOME/bin:$PATH"

COPY ./setup.sh $SETUP_HOME/
RUN $SETUP_HOME/setup.sh $SETUP_HOME && rm -f $SETUP_HOME/setup.sh
