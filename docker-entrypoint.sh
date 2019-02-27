#!/bin/bash
set -e

build() {
    local var="$1"
    local stmt="$2"
    export $var+="$(printf "\n${stmt}")"
}

run() {
    echo "${!1}" | ${PREFIX}/bin/isql
}

createNewPassword() {
    # openssl generates random data.
        openssl </dev/null >/dev/null 2>/dev/null
    if [ $? -eq 0 ]
    then
        # We generate 40 random chars, strip any '/''s and get the first 20
        NewPasswd=`openssl rand -base64 40 | tr -d '/' | cut -c1-20`
    fi

        # If openssl is missing...
        if [ -z "$NewPasswd" ]
        then
                NewPasswd=`dd if=/dev/urandom bs=10 count=1 2>/dev/null | od -x | head -n 1 | tr -d ' ' | cut -c8-27`
        fi

        # On some systems even this routines may be missing. So if
        # the specific one isn't available then keep the original password.
    if [ -z "$NewPasswd" ]
    then
        NewPasswd="masterkey"
    fi

        echo "$NewPasswd"
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

confSet() {
    confFile="${PREFIX}/firebird.conf"
    # Uncomment specified value
    sed -i "s/^#${1}/${1}/g" "${confFile}"
    # Set Value to new value
    sed -i "s~^\(${1}\s*=\s*\).*$~\1${2}~" "${confFile}"
}

# Create any missing folders


if [[ ! -e "${VOLUME}/etc/" ]]; then
    echo "create settings file"
    mkdir -p "${VOLUME}/etc/"
    mkdir -p "${VOLUME}/system"
    mkdir -p "${VOLUME}/log"
    mkdir -p "${VOLUME}/data"
    
    file_env 'EnableLegacyClientAuth'
    file_env 'EnableWireCrypt'
    if [[ ${EnableLegacyClientAuth} == 'true' ]]; then
        confSet AuthServer "Legacy_Auth, Srp, Win_Sspi"
        confSet AuthClient "Legacy_Auth, Srp, Win_Sspi"
        confSet UserManager "Legacy_UserManager, Srp"
        confSet WireCrypt "enabled"
    fi
    if [[ ${EnableWireCrypt} == 'true' ]]; then
        confSet WireCrypt "enabled"
    fi
    
    cp "${PREFIX}/firebird.conf" "${VOLUME}/etc/firebird.conf"
    cp "${PREFIX}/databases.conf" "${VOLUME}/etc/databases.conf"
    cp "${PREFIX}/fbtrace.conf" "${VOLUME}/etc/fbtrace.conf" 
    cp "${PREFIX}/replication.conf" "${VOLUME}/etc/replication.conf"
    
else 
    echo "copy settings file"
    cp "${VOLUME}/etc/firebird.conf" "${PREFIX}/firebird.conf"
    cp "${VOLUME}/etc/databases.conf" "${PREFIX}/databases.conf"
    cp "${VOLUME}/etc/fbtrace.conf" "${PREFIX}/fbtrace.conf"
    cp "${VOLUME}/etc/replication.conf" "${PREFIX}/replication.conf"
fi

# ln -s "${PREFIX}/firebird.log" "${VOLUME}/log/firebird.log"

if [ ! -f "${VOLUME}/system/security4.fdb"  ]; then
    cp "${PREFIX}/skel/security4.fdb" "${PREFIX}/security4.fdb"
    file_env 'ISC_PASSWORD'
    if [ -z ${ISC_PASSWORD} ]; then
       ISC_PASSWORD=$(createNewPassword)
       echo "setting 'SYSDBA' password to '${ISC_PASSWORD}'"
    fi

    ${PREFIX}/bin/isql -user sysdba "${PREFIX}/security4.fdb" <<EOL
create or alter user SYSDBA password '${ISC_PASSWORD}';
commit;
quit;
EOL

    cp -f "${PREFIX}/security4.fdb" "${VOLUME}/system/security4.fdb"

    cat > "${PREFIX}/SYSDBA.password" <<EOL
# Firebird generated password for user SYSDBA is:
#
ISC_USER=sysdba
ISC_PASSWORD=${ISC_PASSWORD}
#
# Also set legacy variable though it can't be exported directly
#
ISC_PASSWD=${ISC_PASSWORD}
#
# generated at time $(date)
#
# Your password can be changed to a more suitable one using
# SQL operator ALTER USER.
#

EOL

    cp -f "${PREFIX}/SYSDBA.password" "${VOLUME}/system/SYSDBA.password"
    
else
    echo "no setting SYSDBA"
    cp "${VOLUME}/system/security4.fdb" "${PREFIX}/security4.fdb"
    cp "${VOLUME}/system/SYSDBA.password" "${PREFIX}/SYSDBA.password"
    
    chown firebird:firebird "${PREFIX}/security4.fdb"
    chmod 660 "${PREFIX}/security4.fdb"
    chmod 600 "${PREFIX}/SYSDBA.password"
    

fi


$@
