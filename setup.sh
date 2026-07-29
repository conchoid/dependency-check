#!/bin/sh

set -eux

apt-get update
apt-get install -y \
	curl \
	gnupg \
	python3 \
	wget \
	unzip

# DependencyCheck
cd /opt
VERSION="12.2.2"
DEPENDENCY_CHECK_ZIP="dependency-check-${VERSION}-release.zip"
		  
DOWNLOAD_URL="https://github.com/dependency-check/DependencyCheck/releases/download/v${VERSION}/${DEPENDENCY_CHECK_ZIP}"
curl -fsSLO "${DOWNLOAD_URL}"
curl -fsSLO "${DOWNLOAD_URL}.asc"
# try to fetch key from multiple servers for better stability.
# https://github.com/docker-library/faq#openpgp--gnupg-keys-and-verification
key="259A55407DD6C00299E6607EFFDE55BE73A2D1ED"
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ${key}
gpg --verify "${DEPENDENCY_CHECK_ZIP}.asc"
rm "${DEPENDENCY_CHECK_ZIP}.asc"
unzip -q "${DEPENDENCY_CHECK_ZIP}"
chmod a+x /opt/dependency-check/bin/dependency-check.sh
ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
dependency-check --version
dependency-check --project DependencyCheck --disableCentral --disableAssembly --format JSON --scan /opt/dependency-check/lib --noupdate || true
chmod -R 777 /opt/dependency-check/data
rm -f dependency-check-report.json

apt-get clean
rm -rf /var/lib/apt/lists/*
