# Docker Hub: conchoid/dependency-check:v13.0.0-1-trixie
FROM debian:trixie-slim

# Preset locale to en_US.UTF-8 and install common tools
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       locales \
       git \
       ssh \
       connect-proxy \
       curl \
       ca-certificates \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /etc/ssh/ssh_host_*_key \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=conchoid/debian:trixie-2-slim /usr/local/bin/git-lfs /usr/local/bin/git-lfs
RUN git lfs install

ENV LANG=en_US.utf8

ENV SETUP_HOME=/opt/dependencycheck

ENV CURL_RETRY_OPT='--retry 3 --max-time 180 --retry-max-time 300'
ENV JVM_PATH=/opt/java/openjdk
RUN mkdir -p ${JVM_PATH}

# Install openjdk11 (Eclipse Temurin)
RUN cd ${JVM_PATH} \
    && curl $CURL_RETRY_OPT -OL "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.32.1%2B1/OpenJDK11U-jdk_x64_linux_hotspot_11.0.32.1_1.tar.gz" \
    && echo "5c3f68887c325d36d852ba534303e1f5f1f5cae7d6cc1e951d73e0d8e98a058d OpenJDK11U-jdk_x64_linux_hotspot_11.0.32.1_1.tar.gz" | sha256sum -c - \
    && tar zxf "OpenJDK11U-jdk_x64_linux_hotspot_11.0.32.1_1.tar.gz" -C ${JVM_PATH} \
    && rm "OpenJDK11U-jdk_x64_linux_hotspot_11.0.32.1_1.tar.gz"

ENV JAVA_HOME=${JVM_PATH}/jdk-11.0.32.1+1
ENV JENV_ROOT=/opt/jenv
ENV PATH="${JENV_ROOT}/shims:${JENV_ROOT}/bin:$JAVA_HOME/bin:$PATH"

COPY ./setup.sh $SETUP_HOME/
RUN $SETUP_HOME/setup.sh $SETUP_HOME && rm -f $SETUP_HOME/setup.sh

# NVD database (odc.mv.db) built locally; see UPDATE_DB.md. No API key is baked in.
COPY --chmod=777 data/ /opt/dependency-check/data/
