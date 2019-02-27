#!/bin/bash
set -e
apt-get update
apt-get install -qy --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    libicu-dev \
    libtommath-dev 
mkdir -p /home/firebird
cd /home/firebird
curl -L -o firebird-source.tar.gz -L \
    "${FBURL}"
tar --strip=1 -xf firebird-source.tar.gz

chmod +x ./install.sh && bash ./install.sh -silent
cd /
rm -rf /home/firebird
apt-get purge -qy --auto-remove \
    bzip2 \
    ca-certificates \
    curl 
rm -rf /var/lib/apt/lists/*


mkdir -p  "${PREFIX}/skel"

mv "${PREFIX}/security4.fdb" "${PREFIX}/skel/security4.fdb"

mkdir -p "${PREFIX}/skel/etc"

cp "${PREFIX}/databases.conf" "${PREFIX}/skel/etc/databases.conf"
cp "${PREFIX}/fbtrace.conf" "${PREFIX}/skel/etc/fbtrace.conf"
cp "${PREFIX}/firebird.conf" "${PREFIX}/skel/etc/firebird.conf"
cp "${PREFIX}/replication.conf" "${PREFIX}/skel/etc/replication.conf"

# Cleaning up to restrict access to specific path and allow changing that path easily to
# something standard. See github issue https://github.com/jacobalberty/firebird-docker/issues/12
sed -i 's/^#DatabaseAccess/DatabaseAccess/g' "${PREFIX}/firebird.conf"
sed -i "s~^\(DatabaseAccess\s*=\s*\).*$~\1Restrict ${DBPATH}~" "${PREFIX}/firebird.conf"

# echo "DatabaseAccess = Full" >>"${PREFIX}/firebird.conf" && \
# echo "ServerMode = SuperClassic" >>"${PREFIX}/firebird.conf" && \
# echo "WireCrypt = Enabled" >>"${PREFIX}/firebird.conf" && \
# echo "AuthServer = Legacy_Auth, Srp, Win_Sspi " >>"${PREFIX}/firebird.conf" && \
# echo "UserManager = Legacy_UserManager, Srp" >>"${PREFIX}/firebird.conf"

ln -s ${PREFIX}/bin/* /usr/local/bin
