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

# Use --noupdate by default so scans rely on the pre-built database baked into
# the image, avoiding any NVD API/feed access at scan time.
# Pass --updateOnly, --nvdDatafeed, or --nvdApiKey explicitly to trigger an update.
# See: https://dependency-check.github.io/DependencyCheck/data/cacheh2.html
cat > /usr/local/bin/dependency-check << 'WRAPPER'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in
        --noupdate|--updateOnly|--nvdDatafeed|--nvdDatafeed=*|--nvdApiKey|--nvdApiKey=*)
            exec /opt/dependency-check/bin/dependency-check.sh "$@"
            ;;
    esac
done
exec /opt/dependency-check/bin/dependency-check.sh --noupdate "$@"
WRAPPER
chmod +x /usr/local/bin/dependency-check

dependency-check --version

apt-get clean
rm -rf /var/lib/apt/lists/*
