#!/bin/bash
set -e
CPUC=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)

apt-get update
apt-get install -qy --no-install-recommends \
    libicu52 \
    libtommath0
apt-get install -qy --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    g++ \
    gcc \
    libicu-dev \
    libncurses5-dev \
    libtommath-dev \
    make \
    zlib1g-dev
mkdir -p /home/firebird
cd /home/firebird
curl -L -o firebird-source.tar.gz -L \
    "${FBURL}"
tar --strip=1 -xf firebird-source.tar.gz
./install.sh
cd /
rm -rf /home/firebird
find ${PREFIX} -name .debug -prune -exec rm -rf {} \;
apt-get purge -qy --auto-remove \
    bzip2 \
    ca-certificates \
    curl \
    g++ \
    gcc \
    libicu-dev \
    libncurses5-dev \
    libtommath-dev \
    make \
    zlib1g-dev
rm -rf /var/lib/apt/lists/*

mkdir -p "${PREFIX}/skel/"

# This allows us to initialize a random value for sysdba password
mv "${VOLUME}/system/security3.fdb" "${PREFIX}/skel/security3.fdb"

# Cleaning up to restrict access to specific path and allow changing that path easily to
# something standard. See github issue https://github.com/jacobalberty/firebird-docker/issues/12
sed -i 's/^#DatabaseAccess/DatabaseAccess/g' "${VOLUME}/etc/firebird.conf"
sed -i "s~^\(DatabaseAccess\s*=\s*\).*$~\1Restrict ${DBPATH}~" "${VOLUME}/etc/firebird.conf"

mv "${VOLUME}/etc" "${PREFIX}/skel"
